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




while($line=<>){
  # interpreter
  if ($line=~ /^#!\/.*/){
    $line=~ s/.*/#!\/usr\/bin\/perl -w/;
  }

  $line = single_while($line);
  $line = single_if($line);
  $line = new_line($line);
  $line = num_op($line);
  $line = var_op($line);
  $line = all_print($line);
  print "$line";
}
