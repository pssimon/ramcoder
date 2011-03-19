#!/usr/bin/perl
# Hellloooo to much spare time ! :)
require v5.10.0;
use feature qw{switch};
use integer;

#debugging etc.
my $V = 101;

#Memory stuff
my $M_NUM = qr{(\d+)};
my $M_REGISTER = qr{R$M_NUM};
my $M_MEMORY = qr{S\[$M_REGISTER\]};
my $M_BOPT = qr{(\+|-|\*|\||&|>>|<<|xor|^|div|/|mod|%|<|<=|>|>=)};
my $M_UOPT = qr{(-)};
my $M_LABEL = qr{(\w+)};

#what our program uses:
my @R;
my @S;
my %labels;

#load it!
my @program = <>; #slurp!


#Preprocessing, loading S, looking for labels.
my $s_loaded = 0;
for(my $ip = 0; $ip <= $#program; $ip++) {
  $program[$ip] =~ s/\s+/ /g; 
  $program[$ip]  =~ s/\s+$//g;
  $program[$ip]  =~ s/^\s+//g;
  $program[$ip]  =~ s/#.*$//;
  if ($program[$ip]  =~ /^$M_LABEL:$/) {
    $labels{$1} = $ip;
    $V > 99 && print "found label '$1' at $ip \n";
  }
  if ($program[$ip]  =~ /^S = ((?:\d+,)*\d+)$/) {
    die "Can't init S twice!\n" if $s_loaded;
    @S = eval('(0,'.$1.')'); #0, so that S will be 1-indexed, this can be changed if you want s 0 indexed.
    $s_loaded = 1;
    $program[$ip] = ''; 
  }
}


for(my $ip = 0; $ip < @program; $ip++) {
  next if $program[$ip] =~ /^\s*$/;
  $V > 100 && print "executing $program[$ip]\n";
  given($program[$ip]) {
    when (/^$M_REGISTER = $M_NUM$/) {
      $V > 99 && print "- Loading $2 to R$1\n";
      $R[$1] = $2;
    }
    when (/^$M_REGISTER = $M_MEMORY$/) {
      $V > 99 && print "- Loading S[R$2] = S[$R[$2]] to R$1\n";
      $R[$1] = $S[$R[$2]];
    }
    when (/^$M_REGISTER = $M_REGISTER$/) {
      $V > 99 && print "- Copying R$2 to R$1\n";
      $R[$1] = $R[$2];
    }
    when (/^$M_MEMORY = $M_REGISTER$/) {
      $V > 99 && print "- Storing R$2 to S[R$1] = S[$R[$1]]\n";
      $S[$R[$1]] = $R[$2];
    }
    when (/^print $M_REGISTER/) {
      $V > 99 && print "- Printing contents of R$1\n";
      print $R[$1]."\n";
    }
    when (/^$M_REGISTER = $M_REGISTER $M_BOPT $M_REGISTER$/) {
      $V > 99 && print "- R$1 = R$2 $3 R$4\n";
      my ($to, $o1, $bopt, $o2) = ($1, $2, $3, $4);
      $bopt = "/" if $bopt eq "div";
      $bopt = "^" if $bopt eq "xor";
      $bopt = "%" if $bopt eq "mod";
      $R[$1] = eval('$R['.$o1.'] '.$bopt.' $R['.$o2.']');
    }
    when (/^$M_REGISTER = $M_UOPT\s*$M_REGISTER$/) {
      $V > 99 && print "- R$1 = $2 R$3\n";
      $R[$1] = -1*$R[$3];
    }
    when (/^$M_LABEL:$/) {
      next;
    }
    when (/^J $M_LABEL\s*$/) {
      die "Unkown label '$1' encountered" unless $labels{$1};
      $ip = $labels{$1} - 1;
    }
    when (/^JZ $M_LABEL, $M_REGISTER\s*$/) {
      die "Unkown label '$1' encountered" unless $labels{$1};
      if($R[$2] == 0) {
        $ip = $labels{$1} - 1;
      }
    }

    when (/^die$/) {
      print "Argh...\n";
      print "S = ".join(" - ",@S)."\n";
      print "R = ".join(" - ",@R)."\n";
      exit;
    }

    default {
      die("Error, can't parse '$program[$ip]' (line $ip)\n");
    }
  }
}
