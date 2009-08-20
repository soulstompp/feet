package Config::ObjectFiles::Config::Container;

use Moose;

my $meta = __PACKAGE__->meta();

requires '_build_slots';
requires '_empty_slots';

has container (isa => ArrayRef[Object], is => 'rw');
has contents (isa => 'ArrayRef[Object]', is => 'rw', required => 1 );

sub BUILD {
    my ($self) = @_;

    $self->make_attributes();
}

sub _make_attributes {
    my ($self) = @_;

    my @slots = $self->slots();

    for my $module_name (keys %module_attributes) {
        print "adding attribute for $module_name\n";
        my $class_name = $module_attributes{$module_name}->{'class'};
        $meta->add_attribute(
                             $module_name, 
                             isa => "ArrayRef[$class_name]", 
                             is => 'rw', 
                             lazy => 1, 
                             builder => "_build_$module_name",
                             clearer => "_clear_$module_name", 
                             predicate => "_has_$module_name", 
                            );
        print "making attribute for $module_name";
        $meta->add_method( "_build_$module_name" => sub { my $self = shift; $self->_build_slot($module_name); } ); 
    }
}

sub _build_slots {
    my ($self) = @_;

    
}

sub _get_child_slots {
    my ($self) = @_;

    my @slots = ();

    #TODO: go through each container that you contain
    my $object (@objects) {
         if ($object->isa('Config::ObjectFiles::Config::Container')) {
             my @these_slots = @{$object->_get_container_slots()}; 
             push @slots, $these_slots;
         }
    }

    return @slots;
}
