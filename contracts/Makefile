#!/usr/bin/env gmake

include ../common.mk

.PHONY: MessageBox clean

all: UserContract SPDContract

UserContract:
	@printf "$(CYAN)*** Compiling $(BLUE)$@$(CYAN)...$(OFF)\n"
	@solc --evm-version paris --bin --abi --optimize --overwrite -o . BS_$@.sol
	@mv $@.bin $@.hex
	@printf "$(CYAN)*** Generating Go bindings for $(BLUE)$@$(CYAN)...$(OFF)\n"
	@abigen --abi=$@.abi --bin=$@.hex --pkg usercontract --out=$@.go
	
SPDContract:
	@printf "$(CYAN)*** Compiling $(BLUE)$@$(CYAN)...$(OFF)\n"
	@solc --base-path . --include-path ../node_modules  --evm-version paris --bin --abi --optimize --overwrite -o . BS_$@.sol
	@mv $@.bin $@.hex
	@printf "$(CYAN)*** Generating Go bindings for $(BLUE)$@$(CYAN)...$(OFF)\n"
	@abigen --abi=$@.abi --bin=$@.hex --pkg spdcontract --out=$@.go
	

clean:
	@printf "$(CYAN)*** Cleaning up...$(OFF)\n"
	@-rm -f UserContract.abi UserContract.hex UserContract.go