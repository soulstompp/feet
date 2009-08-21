package Feet::Extractor::Source::General;

use Moose;

with 'Feet::Extractor::Interface::SourceDriver';

use Config::General;

use Feet::Object;

use Data::Dumper;

has file_name => ( isa => 'Str', is => 'ro', required => 1 );

sub _extract_objects {
    my ($self) = @_;

    my @objects;

    my $conf = Config::General->new($self->file_name());

    my %config = $conf->getall();

    for my $category (keys %config) {
        for my $key (keys %{$config{$category}}) {
            push @objects, Feet::Object->new(category => $category, properties => $config{$category}->{$key});
        }
    }

    return \@objects;
}

no Moose;

return 1;
