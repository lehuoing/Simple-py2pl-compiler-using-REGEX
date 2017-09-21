#!/usr/bin/perl -w
sub new_line {
  my ($line) = @_;
  # newline
  if ($line!~ /\n$/){
      $line="$line\n";
  }
  return $line;
}

sub all_print {
  my ($line) = @_;
  # print strings
  if ($line=~ /^print\(\".*\"\)/){
    $line=~ s/print\(/print /;
    $line=~ s/\"\)/\\n\";/;
  }
  # print variables
  elsif ($line=~ /^print\(\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\)/){
    $line=~ s/print\(/print \"\$/;
    $line=~ s/\)/\\n\";/;
  }
  # print operators among variables
  elsif ($line=~ /^print\(\s*(?:[a-zA-Z_][a-zA-Z0-9_]*)(?:\s*(?:[\+\-\*\/%]|(?:\/\/)|(?:\*\*))\s*(?:[a-zA-Z_][a-zA-Z0-9_]*))+\s*\)/){
    $line=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
    $line=~ s/\$print\(/print /;
    $line=~ s/\)/, \"\\n\";/;
  }
  elsif ($line=~ /^print\(\)/){
    $line="print \"\\n\";\n";
  }
  return $line;
}

sub num_op {
  my ($line) = @_;
  # numeric constants and operators
  if ($line=~ /^([a-zA-Z_][a-zA-Z0-9_]*)(\s*=\s*(?:\d+)(?:\s*(?:[\+\-\*\/%]|(?:\/\/)|(?:\*\*))\s*\d+)*)/){
    $v_name=$1;
    $right_side=$2;
    $line="\$$v_name$right_side;\n";
  }
  return $line;
}

sub var_op {
  my ($line) = @_;
  # operators among variables
  if ($line=~ /^[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*(?:[a-zA-Z_][a-zA-Z0-9_]*)(?:\s*(?:[\+\-\*\/%]|(?:\/\/)|(?:\*\*))\s*(?:[a-zA-Z_][a-zA-Z0-9_]*))*/){
    $line=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
    $line=~ s/\n/;\n/;
  }
  return $line;
}


sub single_while {
  my ($line) = @_;
  # single line while loop
  if ($line=~ /^while (.+)\:\s(.+)/){
      $need_print="";
      $condition=$1;
      $imple=$2;
      $condition=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/;
      $condition="while ($condition) {\n";
      $need_print="$need_print"."$condition";
      @imple_list=split(/;/,$imple);
      foreach $e(@imple_list){
        $e=~ s/^\s*//;
        $e = new_line($e);
        $e = num_op($e);
        $e = var_op($e);
        $e = all_print($e);
        $need_print="$need_print"."\t$e";
      }
      $need_print="$need_print"."}\n";
      return $need_print;
  }
  return $line;
}

sub single_if {
  my ($line) = @_;
  # single line if condition
  if ($line=~ /^if (.+)\:\s(.+)/){
      $need_print="";
      $condition=$1;
      $imple=$2;
      $condition=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/;
      $condition="if ($condition) {\n";
      $need_print="$need_print"."$condition";
      @imple_list=split(/;/,$imple);
      foreach $e(@imple_list){
        $e=~ s/^\s*//;
        $e = new_line($e);
        $e = num_op($e);
        $e = var_op($e);
        $e = all_print($e);
        $need_print="$need_print"."\t$e";
      }
      $need_print="$need_print"."}\n";
      return $need_print;
  }
  return $line;
}

sub common_while {
  my ($line) = @_;
  if ($line=~ /^while (.+)\:\s*$/) {
    $line=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
    $line=~ s/\$while /while \(/;
    $line=~ s/:/\) {/;
  }
  return $line;
}

sub common_if {
  my ($line) = @_;
  if ($line=~ /^if (.+)\:\s*$/) {
    $line=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
    $line=~ s/\$if /if \(/;
    $line=~ s/:/\) {/;
  }
  if ($line=~ /^elif (.+)\:\s*$/) {
    $line=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
    $line=~ s/\$elif /elsif \(/;
    $line=~ s/:/\) {/;
  }
  if ($line=~ /^else/){
    $line=~ s/\:/ {/;
  }
  return $line;
}

sub standard_output {
  my ($line) = @_;
  if ($line=~ /^sys.stdout.write\((.+)\)/) {
    $line="print $1;\n";
  }
  return $line;
}

sub standard_readline {
  my ($line) = @_;
  if ($line=~ /^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*int\(sys\.stdin\.readline\(\)\)/){
      my $variable = $1;
      $line="\$$variable = <STDIN>;\n";
  }
  return $line;
}

sub change_breaknext {
  my ($line) = @_;
  if ($line=~ /^break/){
    $line=~ s/break/last;/;
  }
  if ($line=~ /^continue/){
    $line=~ s/continue/next;/;
  }
  return $line;
}




$pre_indent='';
while($line=<>){
  # interpreter
  if ($line=~ /^#!\/.*/){
    $line=~ s/.*/#!\/usr\/bin\/perl -w/;
  }
  # remove import
  if ($line=~ /^import/){
    $line="\n";
  }
  if ($line =~ /^\s*(#|$)/){
    print $line;
    next;
  }
  # different indents
  $line=~/^(\s*).+/;
  $curr_indent=$1;
  $line=~ s/^$curr_indent//;
  if ($curr_indent!~ /^$pre_indent/){
      print "$curr_indent"."}\n";
  }

  $line = common_while($line);
  $line = common_if($line);
  $line = single_while($line);
  $line = single_if($line);
  $line = standard_output($line);
  $line = standard_readline($line);
  $line = new_line($line);
  $line = num_op($line);
  $line = var_op($line);
  $line = change_breaknext($line);
  $line = all_print($line);
  print "$curr_indent"."$line";
  $pre_indent=$curr_indent;
}
if ($curr_indent ne '') {
  print "}\n";
}
