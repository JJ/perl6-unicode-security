use v6.c;
unit class Unicode::Security:ver<0.0.1>;


use JSON::Fast;
my $spec = CompUnit::DependencySpecification.new(:short-name<Unicode::Security>);
my $dist = $*REPO.resolve($spec).distribution;
my %confusables = from-json "resource/{$dist.meta<resources>[0]}".IO.slurp;
my @confusables-sources;
my @confusables-targets;

for %confusables.kv -> $key, @values {
    for @values -> $v {
        push @confusables-sources: $key;
        push @confusables-targets: $v;
    }
}

my %confusables-ws = from-json "resource/{$dist.meta<resources>[1]}".IO.slurp;
my %confusables-ws-sets;

for %confusables-ws.keys -> $key {
    for %confusables-ws{$key}.keys -> $k {
        %confusables-ws-sets{$key}{$k} = set  %confusables-ws{$key}{$k}.list;
    }
}

# for %confusables.keys {
#     say "$_ {$_.uniname} ", :16( ~$_.ord ), " ";
#     for @(%confusables{$_}) -> $c {
#         say $c.NFD.Str;
#     }
# }

sub confusables( $c where %confusables{$c} ) is export {
    return  %confusables{$c}
}

sub confusables-whole-script( $c where %confusables-ws{$c} ) is export {
    return  %confusables-ws{$c}
}

sub skeleton( $string ) is export {
    my $copy = $string.NFD.Str;
    $copy.=trans( @confusables-sources => @confusables-targets );
    return $copy
}

sub confusable( $this-string, $that-string ) is export {
    return skeleton( $this-string) eq skeleton( $that-string );
}

sub soss( $string ) is export is pure {
    my %soss;
    for $string.comb -> $c {
        my $script = $c.uniprop("Script") // "Unknown";
        %soss{$script}.push: $c if $script eq none("Common","Inherited");
    }
    return %soss;
}

sub whole-script-confusable( $target, $str ) is export {
    my $norm-target = $target.wordcase;
    my %soss = soss($str.NFD.Str) || return False;
    my @scripts = %soss.keys;
    return False if @scripts.elems > 1;
    my $source = @scripts.pop;
    my $char-set = %confusables-ws-sets{$source}{$norm-target};
    return True if $char-set ∩ %soss{$source}.list.Set;
    
}

sub mixed-script-confusable( $str ) is export {
    my %soss = soss($str.NFD.Str);
    say %soss.keys;
    for %soss.keys -> $source {
        my $sum = 0;
        for %soss.keys -> $target {
            next if $target eq $source;
            my $char-set = %confusables-ws-sets{$target}{$source};
            last unless $char-set ∩ %soss{$target}.list.Set;
            $sum++;
        }
        return True if 1 == ( %soss.keys.elems - $sum );
    }
    return False;
    
}

=begin pod

=head1 NAME

Unicode::Security - blah blah blah

=head1 SYNOPSIS

=begin code :lang<perl6>

use Unicode::Security;

=end code

=head1 DESCRIPTION

Unicode::Security is ...

=head1 AUTHOR

JJ Merelo <jjmerelo@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2019 JJ Merelo

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
