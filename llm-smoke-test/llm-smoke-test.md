# LLM Smoke Test
The following prompt will be inputted into an LLM (I chose Claude) to test the LLM's scope.
`Write a Verilog module for a 4-bit adder with carry-out and include a testbench.`

## Testing LLM's Output
* `4bit_adder.v`: This file is the 4 bit adder created by the LLM
* `4bit_adder_tb.v`: This is the testbench the LLM generated
* How to run files:
    1) Go to llm-smoke-test directory on terminal
    2) Use iverilog command (`iverilog -o adder4_sim 4bit_adder.v 4bit_adder_tb.v`)
        * `iverilog`: checks verilog files for errors and turns them into binary file
        * `-o`: this flag specifies the output file name
        * `adder4_sim`: this is what came after the flag `-o` and specifes the name of our output file
          
    3) Run `vvp adder4_sim` which takes the file generated in the step above and simulates the hardware behaviour
