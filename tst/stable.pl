#!/usr//bin/perl

my @ids;
my $nv = 0;

for $i (0 .. $#ARGV) {
   dofile ($ARGV[$i], $i);
}

@ids = sort { $a->[1] <=> $b->[1] } @ids;

print "ids: $#ids+1\n";

for ($i = 0; $i <= $#ids; $i++) {
 printf ("%d %.7f %s\n", $ids[$i]->[0], $ids[$i]->[1], $ids[$i]->[2]);
}

my $s = 0;
for $i (0 .. $#ARGV) {
   $s = check ($ARGV[$i], $i);
   if ($s == 0) {
       print "unstable $i\n";
       exit (0);
   }
   print "$ARGV[$i]: stable\n";
}
print "stable $#ARGV\n";
exit(17);


sub findindex {
  my $i = 0;
  for ($i = 0; $i <= $#ids; $i++) {
      if ($ids[$i]->[2] eq $_[0]) {
	  return $i;
      }
  }
  print "findindex: couldn't find $_[0]\n";
  exit;
}

sub findsucc {
  my $i = 0;
  my $j;
  for ($i = 0; $i <= $#ids; $i++) {
      $j = ($i+1) % ($#ids+1);
      if (($ids[$i]->[1] <= $_[0]) &&
	  ($_[0] < $ids[$j]->[1])) {
	  return $j;
      }
  }
  return 0;
}

sub check {
    my $f = $_[0];
    my $n = $_[1];
    my $id;
    my $i;
    my $j;
    my $s = 1;
    my $node;
    my $last;
    my $m;

    print "$f\n";
    open (FILE, $f);
    while (defined ($line = <FILE>)) {
	if ($line =~ /CHORD NODE STATS/) {
	    print "new check\n";
	    $last = "";
	    $s = 1;
	}
	if ($line =~ /===== ([a-f0-9]+)/) {
	    $node = $1;
	    $i = findindex ($node);
	    # print "check: $i: $ids[$i]->[2]\n";
	}
	if ($line =~ /finger: (\d+) : ([a-f0-9]+) : succ ([a-f0-9]+)/) {
	    $m = convert ($2);
	    $j = findsucc ($m);
	    if ($ids[$j]->[2] ne $3) {
		print "$1: expect succ to be $ids[$j]->[2] instead of $3\n";
		$s = 0;
	    }
	}
	if ($line =~ /double: (\d+) : ([a-f0-9]+) : succ ([a-f0-9]+)/) {
	    $m = convert ($2);
	    $j = findsucc ($m);
	    if ($ids[$j]->[2] ne $3) {
		print "$1: expect succ(double) to be $ids[$j]->[2] instead of $3\n";
		$s = 0;
	    }
	}
	if ($line =~ /succ (\d+) : ([a-f0-9]+)/) {
            $i = ($i+1) % ($#ids+1);
            if ($ids[$i]->[2] ne $2) {
		$last = "check: $node ($n): $1 $i: expect $ids[$i]->[2] instead of $2\n";
		$s = 0;
	    }
	}
	if ($line =~ /pred :  ([a-f0-9]+)/) {
	    $m = convert ($1);
	    $j = findsucc ($m);
	    if ($ids[$j]->[2] ne $node) {
		print "$1 pred is $ids[$j]->[2] instead of $node\n";
		$s = 0;
	    }
	}
    }
    close (FILE);
    print $last;
    return $s;
};

sub dofile {
    my $f = $_[0];
    my $n = $_[1];
    print "$f\n";
    open (FILE, $f);
    while (defined ($line = <FILE>)) {
	if ($line =~ /myID is ([a-f0-9]+)/) {
	    my $id = convert ($1);
	    # print "$n: $id\n";
	    $ids[$nv++] = [$n, $id, $1];
	}
    }
    close (FILE);
}

sub convert {
    my($id) = @_;

    while(length($id) < 40){
        $id = "0" . $id;
    }

    my $i;
    my $x = 0.0;
    for($i = 0; $i < 10; $i++){
        if($id =~ /^(.)/){
            my $c = $1;
            $id =~ s/^.//;
            $x *= 16.0;
            if($c =~ /[0-9]/){
                $x += ord($c) - ord('0');
            } else {
                $x += ord($c) - ord('a') + 10;
            }
        }
    }
    return $x / 1048575.0;
}
