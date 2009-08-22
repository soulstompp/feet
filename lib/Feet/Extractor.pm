package Feet::Extractor;

use Module::Pluggable::Object;

use Moose;

use MooseX::AttributeHelpers;

use Data::Dumper;

use aliased 'Feet::Extractor::Interface::SourceDriver';

has source => ( is => 'ro', isa => 'Str', required => 1, default => 'General' );

has _source_driver => ( is => 'ro', isa => 'Feet::Extractor::Interface::SourceDriver', lazy_build => 1 );

has _driver_args => (is => 'ro', isa => 'HashRef', required => 0);

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

sub _build__source_driver {
    my ($self) = @_;

    my $class = undef; 
 
    my $base = __PACKAGE__ . '::Source';

    my $mp = Module::Pluggable::Object->new(
                                            search_path => [$base],
                                           );

    my $class_found = 0;

    for my $class_name ($mp->plugins()) {
        (my $name) = $class_name =~ /^\Q${base}::\E(.+)/;

        if ($name eq $self->source()) {
            $class = $class_name;
            $class_found = 1;
        }

        last if $class_found;
    }

    confess "Class ${class} in ${base}:: namespace does not appear to exist" unless $class_found;

    Class::MOP::load_class($class);

    unless ($class->does(SourceDriver)) {
        confess "Class ${class} in ${base}:: namespace does not implement Source Driver interface";
    }

    my $source_driver = $class->new(%{$self->_driver_args()});

    return $source_driver;
}

sub extract {
    my ($self) = @_;

    return $self->_source_driver()->_extract_objects();
}

__PACKAGE__->meta->make_immutable();

1;
