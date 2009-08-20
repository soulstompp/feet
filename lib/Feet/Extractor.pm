package Feet::Extractor;

use Module::Pluggable::Object;

use Moose;

use aliased 'LolCatalyst::Lite::Interface::SourceDriver';

has source => ( is => 'ro', isa => 'Str', required => 1, default => 'General' );

has _sources => ( is => 'ro', isa => 'HashRef[Str]', lazy_build => 1 );

has objects => (
                metaclass => 'Collection::Array', 
                isa => 'ArrayRef[Feet::Object]', 
                is => 'rw', 
                provides => {
                             'push' => 'add_objects',
                             'pop'  => 'remove_last_object',
                            },
               );

sub _build__sources {
    my ($self) = @_;

    my $base = __PACKAGE__ . '::Source';

    my $mp = Module::Pluggable::Object->new(
                                            search_path => [$base],
                                           ); 

    my @classes = $mp->plugins;

    my %sources;

    foreach my $class (@classes) {
        Class::MOP::load_class($class);

        unless ($class->does(SourceDriver)) {
             confess "Class ${class} in ${base}:: namespace does not implement Translation Driver interface";
        }

        (my $name = $class) =~ s/^\Q${base}::\E//;

        $sources{$name} = $class->new;
    }

    return \%sources;
}

sub extract_from {
    my ($self, $source_type) = @_;

    return $self->_sources->{$source_type}->extract();
}

sub can_extract_from {
    my ($self, $source_type) = @_;

    return exists $self->_sources->{$source_type};
}

__PACKAGE__->meta->make_immutable();

1;
