import torch
import time
from transformers import GPT2Model, GPT2Config
from torch.profiler import profile, record_function, ProfilerActivity

# GPT-2 Small config (117M parameters)
config = GPT2Config(
    n_layer=12,
    n_head=12,
    n_embd=768,
    vocab_size=50257,
)

model = GPT2Model(config)
model.eval()

# Dummy input: batch=1, seq_len=128
batch_size = 1
seq_len    = 128
input_ids  = torch.randint(0, config.vocab_size, (batch_size, seq_len))

# Warmup runs (not measured)
with torch.no_grad():
    for _ in range(3):
        _ = model(input_ids)

# Profile 10 runs with torch.profiler
with profile(
    activities=[ProfilerActivity.CPU],
    record_shapes=True,
    with_flops=True,
) as prof:
    with torch.no_grad():
        for _ in range(10):
            with record_function("gpt2_inference"):
                _ = model(input_ids)

# Print top 20 ops by CPU time
print("=== Top 20 ops by CPU time ===")
print(prof.key_averages().table(sort_by="cpu_time_total", row_limit=20))

# Save full output to project_profile.txt
output_path = "project_profile.txt"
with open(output_path, "w") as f:
    f.write("=== GPT-2 Small Profiling (10 runs, batch=1, seq_len=128) ===\n\n")
    f.write(prof.key_averages().table(sort_by="cpu_time_total", row_limit=50))

print(f"\nSaved profiler output to {output_path}")
