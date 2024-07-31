use strict;
use warnings;
our $Zstep; our $lastZmmbelowfail; our $lastZlinebelowfail;
our $ZmmOffset; our $EmmOffset; our $homed;
our $doprintmoves; our $comment; our $command;
our $lastM204; our $lastM205; our $debugmode;
our $writehandle;
print "
What height(mm) did the print fail at?:
Z";
<STDIN>=~/\d+(\.\d+)?/g and our $cutheight=$& or die "Use the format Int or Int.Int only!";
our $outputfilename=$ARGV[0]=~s/(.*)(\.[^.]*)/$1CUT$2/r;
$debugmode and print "$outputfilename will start from about $cutheight mm $/";


push @ARGV, $ARGV[0];
while (@ARGV){
 $_=<>;
 eof
  and close ARGV
  and last; #close ARGV resets line number ($.=0)
 s/;.*//;
 /^G[01].*?\sZ([^+-]+?)\s/o 
  and $1<$cutheight
  and $lastZlinebelowfail=$.;
#  and $lastZmmbelowfail=$1;
 #zhop debug: /^G[01].*?\sZ(\S+)/o and say "I am $1mm high on Zstep", ++$Zstep,"line $.";
}
$debugmode and print "all moves before line $lastZlinebelowfail must be disabled.$/";

unless ($debugmode) {
 open $writehandle, '>', $outputfilename
  or die "Cannot open file $outputfilename: $!";
 binmode $writehandle; #enable binmode to avoid conversion slow-downs
 select($writehandle);
}

while (<>) {
 unless ($doprintmoves) {
 $debugmode and print "L$.";
 undef $command;
 #strip and extract comments
 /;/o and s/(;[^\n]*)\n?+/\n/g and $comment=$1
  or undef $comment;
  chomp;
  
 #preserve M
 /^M\d+/o and $command=$_ ;
 
 #check if above failure point
 $doprintmoves
  or $lastZlinebelowfail<=$. and $doprintmoves++;

 #track the E position
 /^G[01].*?\sE([^+-]+?)(\s|$)/o and $EmmOffset=$1;
 #track the Z position
 /^G[01].*?\sZ([^+-]+?)(\s|$)/o and $ZmmOffset=$1;
 
 #track m204 state
 /^M204\s+?S[\d\.]+/o and $lastM204=$& and next;
 #track m205 state
 /^M205\s+?([XY][\d\.]+\s?)+/o and $lastM205=$& and next;

 #skip or enable move commands
 /^(G[01] |^\n$)/o and $doprintmoves ? $command=$_ : next;
 /^G(2[6789]|[3456]\d)/o and $homed and next; #skip repeating homing related commands
 $homed
  or /G(2[6789]|[3456]\d)/o
  and $command = "G28 F600 X0 Y0; replacing any homing command with a single XY homing"
  and $homed++; #run a single XY homing command only

 #offset the initial print conditions by pre-pending g92
 $doprintmoves && $EmmOffset && $ZmmOffset and $command ="G92 Z$ZmmOffset E$EmmOffset;Prepending Z and E offset\n".$command;
 $doprintmoves && $lastM204 && $lastM205 and $command =$lastM204.";Prepending M204 in its last state\n".$lastM205.";Prepending M205 in its last state\n".$command;

 # printing whatever has left over.
 print $command ? $command:$_,$comment ? $comment:"","\n"; 
 next;
 } else {
 $debugmode ? print "P$.": print $_;
 }
}

unless ($debugmode) {select(STDOUT); close $writehandle or die "Cannot close file $outputfilename: $!";}
exit;
#https://marlinfw.org/meta/gcode/ --gcode reference guide 

#/G([0-6]|10)[^FXYZE]+?[FXYZE]/o -- overly strict print move pattern 
#stolen from a youtube comment:
#Cura uses absolute extrusion in defult, 
#so if we dont use G92 to set the offset of the extruder,
# the printhead will move to the xyz axis of the first line
# of gcode and continuously extrude filaments until it reaches
# the extruder(E) distance, ending up with a huge huge blob.
# So what I did to fix this problem is to not delete everything
# in the printer startup gcode section, but to keep the
# 'G92 E0; Reset Extruder' line, and replace the E0 with whatever E
# distance you want it to continue from. so in my case was 942.12175,
# so I replace the E0 to E942.12175.