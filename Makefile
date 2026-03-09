.PHONY: install uninstall update test

install:
	@bash scripts/install.sh

uninstall:
	@bash scripts/uninstall.sh

update:
	@bash scripts/update.sh

test:
	@echo "=== PreToolUse Hook 테스트 ==="
	@echo '{"tool_name":"Bash","tool_input":{"command":"ls -la /tmp 2>/dev/null"}}' | bash scripts/pretooluse-bash.sh && echo "✓ ls + redirect: approve"
	@echo '{"tool_name":"Bash","tool_input":{"command":"kubectl delete pod foo"}}' | bash scripts/pretooluse-bash.sh 2>/dev/null; [ $$? -eq 2 ] && echo "✓ kubectl delete: block"
	@echo '{"tool_name":"Bash","tool_input":{"command":"ls; kubectl apply -f x.yaml"}}' | bash scripts/pretooluse-bash.sh 2>/dev/null; [ $$? -eq 2 ] && echo "✓ compound deny: block"
	@echo '{"tool_name":"Bash","tool_input":{"command":"git status && git diff"}}' | bash scripts/pretooluse-bash.sh && echo "✓ git chain: approve"
	@echo "=== 완료 ==="
