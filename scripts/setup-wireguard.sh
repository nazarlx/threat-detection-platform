#!/bin/bash
EC2_IP=$(cd ../terraform && terraform output -raw honeypot_public_ip)
EC2_PUBKEY=$(ssh -i ~/.ssh/honeypot-key.pem ubuntu@$EC2_IP "cat /etc/wireguard/ec2_public.key" 2>/dev/null)

echo "EC2 IP: $EC2_IP"
echo "EC2 Public Key: $EC2_PUBKEY"
echo ""
echo "Add this to C:\\WireGuard\\honeypot.conf on Windows:"
echo "[Peer]"
echo "PublicKey = $EC2_PUBKEY"
echo "AllowedIPs = 10.8.0.2/32"
