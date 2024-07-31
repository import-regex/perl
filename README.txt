ContinueFailedPrint.pl
  This perl script edits .gcode files.
  The user provides path to the original .gcode file of the failed print.
  When prompted he inputs the physically measured height of the print failure.
  The script removes all print and travel commands that occur below the point of a failed print.
  To determine the correct point it first scans trough the .gcode file to find the last line in which the printer nozzle is at or slightly below the height at failure.
  There are a few mechanisms to track, discard and modify different G and M prefix commands, mainly consisting of boolean chains and regex capture groups.
