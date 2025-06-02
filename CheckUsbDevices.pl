use strict;
use warnings;
use Win32::API;
local $/;

# Load API functions
my $GetLogicalDriveStrings = Win32::API->new(
    'kernel32', 'GetLogicalDriveStringsA', ['N', 'P'], 'N'
);
die "Could not import GetLogicalDriveStrings" unless $GetLogicalDriveStrings;

my $GetDriveType = Win32::API->new(
    'kernel32', 'GetDriveTypeA', ['P'], 'N'
);
die "Could not import GetDriveType" unless $GetDriveType;

my $GetVolumeInformation = Win32::API->new(
    'kernel32', 'GetVolumeInformationA',
    ['P', 'P', 'N', 'P', 'P', 'P', 'P', 'N'],
    'I'
);
die "Could not import GetVolumeInformation" unless $GetVolumeInformation;

# Prepare a buffer and call GetLogicalDriveStrings
my $buffer = " " x 256;
$GetLogicalDriveStrings->Call(256, $buffer) or die "Failed to get drive strings" ;
# Drive type descriptions
my %drive_types = (
    0 => "The drive type cannot be determined.",
    1 => "The root directory does not exist.",
    2 => "The disk is removable drive.",
    3 => "The disk is non removable.",
    4 => "The drive is a remote (network) drive.",
    5 => "The drive is a CD-ROM drive.",
    6 => "The drive is a RAM disk."
);

# Parse the buffer and check each drive
my @bufferarray =split(/ /, $buffer=~s/[\s\n\0]+/ /msgr);
# error checking the buffer parser: print ("buffering:",@bufferarray,"now reading stuff\n");
for my $drive (@bufferarray) {
 my $type_code = $GetDriveType->Call($drive);
 my $type_description = $drive_types{$type_code} // 'Unknown type';
 my $volume_name_buffer = " " x 256;  # buffer for volume name
 my $filesystem_name_buffer = " " x 256;  # buffer for file system type
 my $volume_serial_number = pack("L", 0);  # buffer for volume serial number
 my $max_component_length = pack("L", 0);  # buffer for max component length
 my $filesystem_flags = pack("L", 0);  # buffer for filesystem flags
 my $result = $GetVolumeInformation->Call(
    $drive,
    $volume_name_buffer,
    256,
    $volume_serial_number,
    $max_component_length,
    $filesystem_flags,
    $filesystem_name_buffer,
    256
);
 print "Drive: $drive\nType:", $type_description=~s/[\s\n\0]+/ /msgr,"\n";
 print "Volume Name:", $volume_name_buffer=~s/[\s\n\0]+/ /msgr,"\n";
 print "File System Type:", $filesystem_name_buffer=~s/[\s\n\0]+/ /msgr,"\n\n";
}





