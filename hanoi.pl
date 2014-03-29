#!/usr/bin/perl
use warnings;
use strict;

my @sticks;
my $n;

sub init_board {
    $sticks[0] = [];
    $sticks[1] = [];
    $sticks[2] = [];
    my $i;
    for ($i = 0; $i < $n; $i++) {
	push(@{$sticks[0]}, $n - $i);
	#$sticsk=[0][$i] = $n - $
    }
}

sub move {
    my($from_stick, $to_stick) = @_;
    if ($from_stick < 0 || $from_stick > 2 || $to_stick < 0 || $to_stick > 2) {
        return 0;
    }
    my $from_val = pop(@{$sticks[$from_stick]});
    my $to_val = $sticks[$to_stick][-1];
    if (defined($from_val) && (!defined($to_val) || ($from_val < $to_val))) {
        push(@{$sticks[$to_stick]}, $from_val);
        return 1;
    }
    else {
        push(@{$sticks[$from_stick]}, $from_val);
        return 0;
    }

}


sub print_board {
    my $stick;
    my $disc;
    my $space = 19;
    print("\n");
    for ($disc = $n - 1; $disc >= 0; $disc--) {
        for($stick = 0; $stick < 3; $stick++) {
            my $disc_width = @{$sticks[$stick]} > $disc ? $sticks[$stick][$disc] : 0;
	    print(" "x($space-$disc_width));
	    print("o"x($disc_width));
	    print("|");
	    print("o"x($disc_width));
	    print(" "x($space-$disc_width));
	}
        print("\n");
    }
    print("\n");
}

sub win {
    return (!@{$sticks[0]} && (!@{$sticks[1]} || !@{$sticks[2]}));
}

sub solve {
    my($from, $to, $index, $swap) = @_;
    if(@{$sticks[$from]} == $index + 1) {
        move($from, $to);
        select(undef, undef, undef, 0.1);
        print_board();
    }
    else {
        my $bottom = @{$sticks[$swap]};
        solve($from, $swap, $index + 1, $to);
        solve($from, $to, $index, $swap);
        solve($swap, $to, $bottom, $from);
    }

}
   


$n = @ARGV ? $ARGV[0] : 5;    
init_board();
print_board();

if (@ARGV >= 2 && $ARGV[1] eq "-h") {
    solve(0, 1, 0, 2);
}
else {

    while(<STDIN>) {
	chomp();
	my($from, $to) = split //;
	if(move($from - 1, $to - 1)) {
	    print_board();
	    if (win()) {
		print("                            YOU WIN!!!!!!\n\n");
		print("                            YOU WIN!!!!!!\n\n");
		print("                            YOU WIN!!!!!!\n\n");
		exit(0);
	    }
	}
	else{
	    print("illegal move!\n");
	}

    }
}
