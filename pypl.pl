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
  if ($line=~ /^print\s*\(\s*\".*\"\s*\)/){
    $line=~ s/print\s*\(/print /;
    $line=~ s/\"\)/\\n\";/;
  }
  elsif ($line=~ /^print\s*\(\s*\'.*\'\s*\)/){
    $line=~ s/print\s*\(/print /;
    $line=~ s/\'\)/\', "\\n";/;
  }
  # print variables
  elsif ($line=~ /^print\s*\(\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\)/){
    $line=~ s/print\s*\(/print \"\$/;
    $line=~ s/\)/\\n\";/;
  }
  # print operators among variables
  elsif ($line=~ /^print\s*\(\s*(?:[a-zA-Z_][a-zA-Z0-9_]*)(?:\s*(?:[\+\-\*\/%]|(?:\/\/)|(?:\*\*))\s*(?:[a-zA-Z_][a-zA-Z0-9_]*))+\s*\)/){
    $line=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
    $line=~ s/\$print\s*\(/print /;
    $line=~ s/\)/, \"\\n\";/;
  }
  elsif ($line=~ /^print\s*\(\s*\"(.*%.*)\"\s*%(.*)\)/) {
    my $need_print=$1;
    my $variable = $2;
    $variable=~ s/\s+//g;
    $need_print=~ s/%\w+/\$$variable/;
    $line="print \"$need_print\\n\";\n";
  }
  elsif ($line=~ /^print\s*\(\s*\)/){
    $line="print \"\\n\";\n";
  }
  elsif ($line=~ /^print\s*\((.*),\s*end\s*=\s*''\s*\)/){
      $nd_print=$1;
      $nd_print=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
      $line="print $nd_print;\n";
  }
  else {
    if ($line=~ /^print\s*\(.*\)/){
        $line=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
        $line=~ s/\$print\s*\(/print /;
        $line=~ s/\)/, \"\\n\";/;
    }
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

sub give_string {
    #give string as value to a variable
    my ($line) = @_;
    if ($line=~ /^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*[\"\'].*[\"\']/){
        my $variable=$1;
        $line=~ s/($variable)/\$$1/;
        $line=~ s/\n/;\n/;
    }

    return $line;
}


sub single_while {
  my ($line) = @_;
  # single line while loop
  if ($line=~ /^while (.+)\:\s*(.+)/){
      $need_print="";
      $condition=$1;
      $imple=$2;
      $condition=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
      $condition="while ($condition) {\n";
      $need_print="$need_print"."$condition";
      @imple_list=split(/;/,$imple);
      foreach $e(@imple_list){
        $e=~ s/^\s*//;
        $e = new_line($e);
        $e = num_op($e);
        $e = var_op($e);
        $e = give_string($e);
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
  if ($line=~ /^if (.+)\:\s*(.+)/){
      $need_print="";
      $condition=$1;
      $imple=$2;
      $condition=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
      $condition="if ($condition) {\n";
      $need_print="$need_print"."$condition";
      @imple_list=split(/;/,$imple);
      foreach $e(@imple_list){
        $e=~ s/^\s*//;
        $e = new_line($e);
        $e = num_op($e);
        $e = var_op($e);
        $e = give_string($e);
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
  if ($line=~ /^sys.stdout.write\s*\((.+)\)/) {
    $line="print $1;\n";
  }
  return $line;
}

sub standard_readline {
  my ($line) = @_;
  if ($line=~ /^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*int\s*\(\s*sys\.stdin\.readline\(\)\s*\)/){
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

sub range_loop {
  my ($line) = @_;
  # for range loop
  if ($line=~ /^for\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+in\s+range\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)/){
      $l_var=$1;
      $range_lower=$2;
      $range_upper=$3;
      $curr_upper=$range_upper-1;
      $line=~ s/^for/foreach/;
      $line=~ s/($l_var)/\$$1/;
      $line=~ s/in\s+range\s*\(.+\)/\($range_lower\.\.$curr_upper\)/;
      $line=~ s/:/{/;
  }
  elsif ($line=~ /^for\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+in\s+range\s*\(\s*(.+)\s*,\s*(.+)\s*\)/){
      $l_var=$1;
      $range_lower=$2;
      $range_upper=$3;
      $line=~ s/^for/foreach/;
      $line=~ s/($l_var)/\$$1/;
      $range_upper="($range_upper - 1)";
      $range_lower=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
      $range_upper=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
      $line=~ s/in\s+range\s*\(.+\)/\($range_lower\.\.$range_upper\)/;
      $line=~ s/:/{/;
  }
  elsif ($line=~ /^for\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+in\s+range\s*\(\s*(.+)\s*\)/){
    $l_var=$1;
    $range_upper=$2;
    $line=~ s/^for/foreach/;
    $line=~ s/($l_var)/\$$1/;
    $range_upper="($range_upper - 1)";
    $range_upper=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
    $line=~ s/in\s+range\s*\(.+\)/\(0\.\.$range_upper\)/;
    $line=~ s/:/{/;
  }
  return $line;
}

sub double_slash {
    my ($line) = @_;
    if ($line=~ /\/\//){
        @test_len= $line=~ /\/\//g;
        if (@test_len == 1){
          $line=~ /\s*(\$?\w+)\s*\/\/\s*(\$?\w+)\s*/;
          $left_handside=$1;
          $right_handside=$2;
          $line=~ s/\s*\$?\w+\s*\/\/\s*\$?\w+/ int\($left_handside \/ $right_handside\)/;
        }
        if (@test_len > 1){
          $line=~ /\s*(\$?\w+)\s*\/\/.*\/\/\s*(\$?\w+)\s*/;
          $line=~ s/\s*(\$?\w+\s*\/\/.*\/\/\s*\$?\w+\s*)/ int\($1\)/;
          $line=~ s/\/\//\//g;
        }
    }
    return $line;
}

sub list_initialize {
    my ($line) = @_;
    if ($line=~ /^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*\[\s*\]/){
        push @list_list, $1;
        $line=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\@$1/;
        $line=~ s/\[\s*\]/\(\)/;
        $line=~ s/\n/;\n/;
    }
    elsif ($line=~ /^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*\[(.*)\]/) {
        my $variable = $1;
        push @list_list, $variable;
        my $right_handside = $2;
        $line="\@$variable = ($right_handside);\n";
    }
    return $line;
}

sub forloop_withstdin {
    my ($line) = @_;
    if ($line=~ /^for\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+in\s+sys\.stdin\s*:/){
        my $variable = $1;
        $line=~ s/($variable)/\$$1/;
        $line=~ s/^for/foreach/;
        $line=~ s/in\s+sys\.stdin/\(<STDIN>\)/;
        $line=~ s/:/{/;
    }
    return $line;
}

sub list_append {
    my ($line) = @_;
    if ($line=~ /^([a-zA-Z_][a-zA-Z0-9_]*)\.append\((.*)\)/){
      my $list_name=$1;
      my $var_name=$2;
      $var_name=~ s/([a-zA-Z_][a-zA-Z0-9_]*)/\$$1/g;
      $line="push \@$list_name, $var_name;\n";
    }

    return $line;
}

sub list_pop {
    my ($line) = @_;
    if ($line=~ /^([a-zA-Z_][a-zA-Z0-9_]*)\.pop\s*\(\s*\)/) {
        my $list_name = $1;
        $line="pop \@$list_name;\n";
    }
    elsif ($line=~ /^\$([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*\$([a-zA-Z_][a-zA-Z0-9_]*)\.\$pop\s*\(\s*\)/) {
        my $variable = $1;
        my $list_name = $2;
        $line="$variable = pop \@$list_name;\n";
    }
    return $line;
}


sub change_len {
    my ($line) = @_;
    if ($line=~ /\$len\(\s*\$ARGV\s*\)/) {
        $line=~ s/\$len\(\s*\$ARGV\s*\)/\@ARGV + 1/g;
    }
    elsif ($line=~ /\$len\(\s*\$(.+?)\)/) {
        $line=~ s/\$len\(\s*\$(.+?)\)/\@$1/g;
    }
    return $line;
}

sub standard_readlines {
    my ($line) = @_;
    if ($line=~ /^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*sys\.stdin\.readlines\s*\(\s*\)/) {
        my $variable = $1;
        my $part1="while (\$line = <STDIN>) {\n";
        my $part2="\tpush \@$1, \$line;\n";
        my $part3="}\n";
        $line=$part1.$part2.$part3;
    }
    return $line;
}

sub change_argv {
    my ($line) = @_;
    if ($line=~ /\bsys\.argv\b/) {
        $line=~ s/\bsys\.argv\b/ARGV/g;
    }
    if ($line=~ /\bARGV\s*(\[\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\])/) {
        my $variable = $1;
        $line=~ s/(\b$variable\b)/$1 - 1/;
    }

    return $line;
}

sub change_notandor {
    my ($line) = @_;
    if ($line=~ /\$not/) {
      $line=~ s/\$not/!/g;
    }
    if ($line=~ /\$and/) {
      $line=~ s/\$and/&&/g;
    }
    if ($line=~ /\$or/) {
      $line=~ s/\$or/||/g;
    }
    return $line;
}



$pre_indent='';
@indent_list=();
@list_list=();
while($line=<>){
  # interpreter
  if ($line=~ /^#!\/.*/){
    $line=~ s/.*/#!\/usr\/bin\/perl -w/;
  }
  # remove import
  if ($line=~ /^import/){
    $line="\n";
  }
  # remove comments and blank lines
  if ($line =~ /^\s*(#|$)/){
    print $line;
    next;
  }
  #dealing with different indents
  $line=~/^(\s*).+/;
  $curr_indent=$1;
  push @indent_list, $curr_indent;
  %count=();
  @indent_list=grep { ++$count{ $_ } < 2 } @indent_list;
  $line=~ s/^$curr_indent//;
  if ($curr_indent!~ /^$pre_indent/){
      for ($i=0;$i<=$#indent_list;$i++){
        if ($indent_list[$i] eq $curr_indent){
            $start_index=$i;
        }
        if ($indent_list[$i] eq $pre_indent){
            $end_index=$i;
        }
      }
      for ($j=$end_index-1;$j>=$start_index;$j--){
          print "$indent_list[$j]"."}\n";
      }
  }

  $line = change_argv($line);
  $line = list_initialize($line);
  $line = common_while($line);
  $line = common_if($line);
  $line = range_loop($line);
  $line = forloop_withstdin($line);
  $line = single_while($line);
  $line = single_if($line);
  $line = standard_output($line);
  $line = standard_readline($line);
  $line = standard_readlines($line);
  $line = new_line($line);
  $line = num_op($line);
  $line = var_op($line);
  $line = give_string($line);
  $line = list_append($line);
  $line = list_pop($line);
  $line = change_breaknext($line);
  $line = all_print($line);
  $line = double_slash($line);
  $line = change_notandor($line);
  $line = change_len($line);
  #change back list variables
  foreach $i (@list_list){
    if ($line=~ /\$$i\b/){
      $line=~ s/\$$i\b/\@$i/g;
    }
  }
  print "$curr_indent"."$line";
  $pre_indent=$curr_indent;
}

if ($curr_indent ne '') {
  $start_index=0;
  for ($i=0;$i<=$#indent_list;$i++){
    if ($indent_list[$i] eq $pre_indent){
        $end_index=$i;
    }
  }
  for ($j=$end_index-1;$j>=$start_index;$j--){
      print "$indent_list[$j]"."}\n";
  }
}
