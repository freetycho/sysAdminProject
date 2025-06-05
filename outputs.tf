output "minecraft_server_connection" {
  value = "Connect to the Minecraft server at ${aws_eip.minecraft_eip.public_ip}:25565"
}

output "nmap_command" {
  value = "Run 'nmap -sV -Pn -p T:25565 ${aws_eip.minecraft_eip.public_ip}' to check connection"
}