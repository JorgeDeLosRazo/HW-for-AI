import torch
import torchvision.models as models
from torchinfo import summary

model = models.resnet18(weights=None).eval()
x = torch.randn(1, 3, 224, 224)

# Save full torchinfo output to file
stats = summary(model, input_size=(1, 3, 224, 224), verbose=0)
with open("/home/jorgerazo/HW-for-AI/codefest/cf01/profiling/resnet18_profile.txt", "w") as f:
    f.write(str(stats))
print("Saved resnet18_profile.txt")

# Top 5 leaf layers by MACs
top5 = sorted(
    [l for l in stats.summary_list if l.is_leaf_layer and l.macs > 0],
    key=lambda l: l.macs, reverse=True
)[:5]

print("\nTop 5 layers by MACs:")
print(f"{'Class':20s} {'Full Path':40s} {'MACs':>12s} {'Params':>10s}")
print("-" * 90)
for l in top5:
    # Build full path by walking up parent_info
    parts = []
    node = l
    while node is not None:
        parts.append(node.var_name)
        node = node.parent_info
    full_path = ".".join(reversed(parts[:-1]))  # exclude root ResNet
    print(f"{l.class_name:20s} {full_path:40s} {l.macs/1e6:>12.2f} M  {l.num_params:>10,}")

# Arithmetic intensity for the top layer
top = top5[0]
mod = top.module
print(f"\nTop layer: {top.class_name} '{top.var_name}'")
print(f"  in_channels : {mod.in_channels}")
print(f"  out_channels: {mod.out_channels}")
print(f"  kernel_size : {mod.kernel_size}")
print(f"  input_size  : {top.input_size}")
print(f"  output_size : {top.output_size}")

C_in  = mod.in_channels
C_out = mod.out_channels
K     = mod.kernel_size[0]
H_in, W_in   = top.input_size[2], top.input_size[3]
H_out, W_out = top.output_size[2], top.output_size[3]

flops         = 2 * top.macs
weight_bytes  = C_in * C_out * K * K * 4
input_bytes   = C_in * H_in * W_in * 4
output_bytes  = C_out * H_out * W_out * 4
total_bytes   = weight_bytes + input_bytes + output_bytes
arith_intensity = flops / total_bytes

print(f"\nArithmetic Intensity Calculation:")
print(f"  FLOPs        = 2 x {top.macs/1e6:.2f} MMACs = {flops/1e6:.2f} MFLOPs")
print(f"  Weights      = {C_in}x{C_out}x{K}x{K} x 4B = {weight_bytes/1e6:.4f} MB")
print(f"  Input acts   = {C_in}x{H_in}x{W_in} x 4B = {input_bytes/1e6:.4f} MB")
print(f"  Output acts  = {C_out}x{H_out}x{W_out} x 4B = {output_bytes/1e6:.4f} MB")
print(f"  Total bytes  = {total_bytes/1e6:.4f} MB")
print(f"  AI           = {flops:.0f} / {total_bytes:.0f} = {arith_intensity:.2f} FLOPs/Byte")
