#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Math::Prime::Util qw/lucas_sequence lucasu lucasv foroddcomposites/;

#my $use64 = Math::Prime::Util::prime_get_config->{'maxbits'} > 32;
my $usexs = Math::Prime::Util::prime_get_config->{'xs'};
my $usegmp = Math::Prime::Util::prime_get_config->{'gmp'};

# Values taken from the OEIS pages.
my @lucas_seqs = (
  [ [1, -1], 0, "U", "Fibonacci numbers",
    [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610] ],
  [ [1, -1], 0, "V", "Lucas numbers",
    [2, 1, 3, 4, 7, 11, 18, 29, 47, 76, 123, 199, 322, 521, 843] ],
  [ [2, -1], 0, "U", "Pell numbers",
    [0, 1, 2, 5, 12, 29, 70, 169, 408, 985, 2378, 5741, 13860, 33461, 80782] ],
  [ [2, -1], 0, "V", "Pell-Lucas numbers",
    [2, 2, 6, 14, 34, 82, 198, 478, 1154, 2786, 6726, 16238, 39202, 94642] ],
  [ [1, -2], 0, "U", "Jacobsthal numbers",
    [0, 1, 1, 3, 5, 11, 21, 43, 85, 171, 341, 683, 1365, 2731, 5461, 10923] ],
  [ [1, -2], 0, "V", "Jacobsthal-Lucas numbers",
    [2, 1, 5, 7, 17, 31, 65, 127, 257, 511, 1025, 2047, 4097, 8191, 16385] ],
  [ [2, 2], 1, "U", "sin(x)*exp(x)",
    [0, 1, 2, 2, 0, -4, -8, -8, 0, 16, 32, 32, 0, -64, -128, -128, 0, 256] ],
  [ [2, 2], 1, "V", "offset sin(x)*exp(x)",
    [2, 2, 0, -4, -8, -8, 0, 16, 32, 32, 0, -64, -128, -128, 0, 256, 512,512] ],
  [ [2, 5], 1, "U", "A045873",
    [0, 1, 2, -1, -12, -19, 22, 139, 168, -359, -1558, -1321, 5148, 16901] ],
  [ [3,-5], 0, "U", "3*a(n-1)+5*a(n-2) [0,1]",
    [0, 1, 3, 14, 57, 241, 1008, 4229, 17727, 74326, 311613, 1306469] ],
  [ [3,-5], 0, "V", "3*a(n-1)+5*a(n-2) [2,3]",
    [2, 3, 19, 72, 311, 1293, 5434, 22767, 95471, 400248, 1678099, 7035537] ],
  [ [3,-4], 0, "U", "3*a(n-1)+4*a(n-2) [0,1]",
    [0, 1, 3, 13, 51, 205, 819, 3277, 13107, 52429, 209715, 838861, 3355443] ],
  [ [3,-4], 0, "V", "3*a(n-1)+4*a(n-2) [2,3]",
    [2, 3, 17, 63, 257, 1023, 4097, 16383, 65537, 262143, 1048577, 4194303] ],
  [ [3,-1], 0, "U", "A006190",
    [0, 1, 3, 10, 33, 109, 360, 1189, 3927, 12970, 42837, 141481, 467280] ],
  [ [3,-1], 0, "V", "A006497",
    [2, 3, 11, 36, 119, 393, 1298, 4287, 14159, 46764, 154451, 510117,1684802]],
  [ [3, 1], 0, "U", "Fibonacci(2n)",
    [0, 1, 3, 8, 21, 55, 144, 377, 987, 2584, 6765, 17711, 46368, 121393] ],
  [ [3, 1], 0, "V", "Lucas(2n)",
    [2, 3, 7, 18, 47, 123, 322, 843, 2207, 5778, 15127, 39603, 103682, 271443]],
  [ [3, 2], 0, "U", "2^n-1 Mersenne numbers (prime and composite)",
    [0, 1, 3, 7, 15, 31, 63, 127, 255, 511, 1023, 2047, 4095, 8191, 16383] ],
  [ [3, 2], 0, "V", "2^n+1",
    [2, 3, 5, 9, 17, 33, 65, 129, 257, 513, 1025, 2049, 4097, 8193, 16385] ],
  [ [4,-1], 0, "U", "Denominators of continued fraction convergents to sqrt(5)",
    [0, 1, 4, 17, 72, 305, 1292, 5473, 23184, 98209, 416020, 1762289, 7465176]],
  [ [4,-1], 0, "V", "Even Lucas numbers Lucas(3n)",
    [2, 4, 18, 76, 322, 1364, 5778, 24476, 103682, 439204, 1860498, 7881196] ],
  [ [4, 1], 0, "U", "A001353",
    [0, 1, 4, 15, 56, 209, 780, 2911, 10864, 40545, 151316, 564719, 2107560] ],
  [ [4, 1], 0, "V", "A003500",
    [2, 4, 14, 52, 194, 724, 2702, 10084, 37634, 140452, 524174, 1956244] ],
  [ [5, 4], 0, "U", "(4^n-1)/3",
    [0, 1, 5, 21, 85, 341, 1365, 5461, 21845, 87381, 349525, 1398101, 5592405]],
);

# 4,4 has D=0.  Old GMP won't handle that.
if ($usexs || !$usegmp) {
  push @lucas_seqs,
  [ [4, 4], 0, "U", "n*2^(n-1)",
    [0, 1, 4, 12, 32, 80, 192, 448, 1024, 2304, 5120, 11264, 24576, 53248] ],
}

my @oeis_81264 = (323, 377, 1891, 3827, 4181, 5777, 6601, 6721, 8149, 10877, 11663, 13201, 13981, 15251, 17119, 17711, 18407, 19043, 23407, 25877, 27323, 30889, 34561, 34943, 35207, 39203, 40501, 50183, 51841, 51983, 52701, 53663, 60377, 64079, 64681);
# The PP lucas sequence is really slow.
$#oeis_81264 = 2 unless $usexs || $usegmp;

plan tests => 0 + 2*scalar(@lucas_seqs) + 1 + 1;

foreach my $seqs (@lucas_seqs) {
  my($apq, $isneg, $uorv, $name, $exp) = @$seqs;
  my $idx = ($uorv eq 'U') ? 0 : 1;
  my @seq = map { (lucas_sequence(2**32-1, @$apq, $_))[$idx] } 0 .. $#$exp;
  do { for (@seq) { $_ -= (2**32-1) if $_ > 2**31; } } if $isneg;
  is_deeply( [@seq], $exp, "lucas_sequence ${uorv}_n(@$apq) -- $name" );
}

foreach my $seqs (@lucas_seqs) {
  my($apq, $isneg, $uorv, $name, $exp) = @$seqs;
  if ($uorv eq 'U') {
    is_deeply([map { lucasu(@$apq,$_) } 0..$#$exp], $exp, "lucasu(@$apq) -- $name");
  } else {
    is_deeply([map { lucasv(@$apq,$_) } 0..$#$exp], $exp, "lucasv(@$apq) -- $name");
  }
}

{
  my @p;
  foroddcomposites {
    my $t = (($_%5)==2||($_%5)==3) ? $_+1 : $_-1;
    my($U,$V) = lucas_sequence($_,1,-1,$t);
    push @p, $_ if $U == 0;
  } $oeis_81264[-1];
  is_deeply( \@p, \@oeis_81264, "OEIS 81264: Odd Fibonacci pseudoprimes" );
}

{
  my $n = 8539786;
  my $e = (0,-1,1,1,-1)[$n%5];
  my($U,$V,$Q) = lucas_sequence($n, 1, -1, $n+$e);
  is_deeply( [lucas_sequence($n, 1, -1, $n+$e)], [0,5466722,8539785], "First entry of OEIS A141137: Even Fibonacci pseudoprimes" );
}
