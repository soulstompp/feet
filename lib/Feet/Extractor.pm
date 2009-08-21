package Feet::Extractor;

use Module::Pluggable::Object;

use Moose;

use MooseX::AttributeHelpers;

use Data::Dumper;

use aliased 'Feet::Extractor::Interface::SourceDriver';

has source => ( is => 'ro', isa => 'Str', required => 1, default => 'General' );

has _sources => ( is => 'ro', isa => 'HashRef', lazy_build => 1 );

has _driver_args => (is => 'ro', isa => 'HashRef[Str]', required => 0);

has objects => (
                metaclass => 'Collection::Array', 
                isa => 'ArrayRef[Feet::Object]', 
                is => 'rw', 
                provides => {
                             'push' => 'add_objects',
                             'pop'  => 'remove_last_object',
                            },
               );

sub BUILDARGS {
    my ($self, %args) = @_;

    my %attributes = %{ $self->meta->get_attribute_map };

    $args{'_driver_args'} = {};
        
    for my $key (keys %args) {
        next if exists $attributes{$key}; 

        $args{'_driver_args'}->{$key} = $args{$key};
        delete $args{$key};
    }

    return \%args;
}


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
             confess "Class ${class} in ${base}:: namespace does not implement Source Driver interface";
        }

        (my $name = $class) =~ s/^\Q${base}::\E//;

        $sources{$name} = $class->new(%{$self->_driver_args()});
    }

    return \%sources;
}

sub extract {
    my ($self) = @_;

    return $self->_sources->{$self->source()}->_extract_objects();
}

sub can_extract_from {
    my ($self, $source_type) = @_;

    return exists $self->_sources->{$source_type};
}

__PACKAGE__->meta->make_immutable();

1;
