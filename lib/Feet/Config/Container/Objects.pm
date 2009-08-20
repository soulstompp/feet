package Config::ObjectFiles::Config::Container::ObjectFiles;

extends 'Config::ObjectFiles::Config::Container';

sub _get_slots {
    my ($self) = @_;

    for my $objects {  
    my (@names) = grep { $_->type() eq 'object_file' } $self->object_files();
   
    my @object_containers = ();

    for my $object_file (@{$self->object_files()) {
        push (@object_files, $object_container);
    }

    return \@object_containers;}
} 
