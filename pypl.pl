#!/usr/bin/perl -w
while($line=<>){
  # newline
  if ($line!~ /\n$/){
      $line="$line\n";
  }
  # interpreter
  if ($line=~ /^#!\/.*/){
    $line=~ s/.*/#!\/usr\/bin\/perl -w/;
  }
  # print strings
  if ($line=~ /print\(\".*\"\)/){
    $line=~ s/print\(/print /;
    $line=~ s/\"\)/\\n\";/;
  }
  # print variables
  elsif ($line=~ /print\([a-zA-Z_][a-zA-Z0-9_]*\)/){
    $line=~ s/print\(/print \"\$/;
    $line=~ s/\)/\\n\";/;
  }
  # print operators among variables
  elsif ($line=~ /print\([ ]*(?:[a-zA-Z_][a-zA-Z0-9_]*)(?:[ ]*(?:[\+\-\*\/%]|(?:\/\/)|(?:\*\*))[ ]*(?:[a-zA-Z_][a-zA-Z0-9_]*))+[ ]*\)/){
    $line=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
    $line=~ s/\$print\(/print /;
    $line=~ s/\)/, \"\\n\";/;
  }
  # numeric constants and operators
  if ($line=~ /^([a-zA-Z_][a-zA-Z0-9_]*)([ ]*=[ ]*(?:\d+)(?:[ ]*(?:[\+\-\*\/%]|(?:\/\/)|(?:\*\*))[ ]*\d+)*)/){
    $v_name=$1;
    $right_side=$2;
    $line="\$$v_name$right_side;\n";
  }
  # operators among variables
  if ($line=~ /^[a-zA-Z_][a-zA-Z0-9_]*[ ]*=[ ]*(?:[a-zA-Z_][a-zA-Z0-9_]*)(?:[ ]*(?:[\+\-\*\/%]|(?:\/\/)|(?:\*\*))[ ]*(?:[a-zA-Z_][a-zA-Z0-9_]*))*/){
    $line=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
    chomp $line;
    $line="$line;\n";
  }


  print "$line";
}
