package Config::ObjectFiles::Config::Container::ObjectFiles;

extends 'Config::ObjectFiles::Config::Container';

sub _get_slots {
    my ($self, $slot_name) = @_;

    my @contents = @{$self->contents()};

    my @containted_slots; 

    for $content (@contents) {
        push @contained_slots, $content->type();
    }

    return \@object_containers; 
}

sub _build_contents {
    my ($self, $slot_name) = @_;

    my @contents = @{$self->objects()};

    return \@contents;
}
