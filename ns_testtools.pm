package ns_testtools{
    use strict;
    use warnings;
# generic test tools for nightsteps modules
    sub new{
        my $class = shift;
        my $this = {};
        bless $this, $class;
        return $class;
    }

    sub printRefArray{
        my ($this, $ra) = @_;
        my $size = @{$ra};
        print "testtools: printing array\n";
        for (my $i=0; $i<$size; $i++){
            print $ra->[$i] . "\n";
        }

    }

    sub printRefHashValues{
        my ($this, $rh_hash) = @_;
        my @keys = keys %{$rh_hash};
        my $size = @keys;
        for (my $i=0; $i < $size; $i++){
            print $keys[$i] . " = " . $rh_hash->{$keys[$i]} . "\n";
        }
    }
}1;