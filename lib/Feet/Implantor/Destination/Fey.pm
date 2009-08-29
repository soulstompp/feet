package Feet::Implantor::Destination::Fey;

use Moose;

with 'Feet::Implantor::Interface::DestinationDriver';

my $meta = __PACKAGE__->meta();

has schema_class => (isa => 'Str', is => 'ro', required => 1);

has schema => (isa => 'Fey::Schema', is => 'ro', lazy => 1, builder => '_build_schema');

has 'object_map' => (
      metaclass => 'Collection::Hash',
      is        => 'rw',
      isa       => 'HashRef[ArrayRef]',
      lazy      => 1,
      default   => sub { {} },
      provides  => {
          exists    => 'exists_in_object_map',
          keys      => 'object_categories',
          get       => 'get_objects_for_category',
          set       => 'set_objects_for_category',
      },
);


sub BUILD {
    my ($self) = @_;

    for my $table ($self->schema()->tables()) {
        next if $table->is_view();

        my $table_name = $table->name();
        my $class_name = Fey::Meta::Class::Table->ClassForTable($table);

        Class::MOP::load_class($class_name);
        
        $meta->add_attribute(
                             $table_name, 
                             isa => "ArrayRef[$class_name]", 
                             is => 'rw', 
                             lazy => 1, 
                             builder => "_build_$table_name",
                             clearer => "_clear_$table_name", 
                             predicate => "_has_$table_name", 
                            );

        $meta->add_method( "_build_$table_name" => sub { my $self = shift; return $self->_build_record_set($table); } ); 
    }
}

sub _build_schema {
    my ($self) = @_;

    my $schema = $self->schema_class()->Schema();

    return $schema;
}

sub _build_record_set {
    my ($self, $table) = @_;

    my $table_name = $table->name();

    my @objects;

    my $class_name = Fey::Meta::Class::Table->ClassForTable($table);

    my @foreign_keys = $table->schema()->foreign_keys_for_table($table);

    my @target_objects;

    my @target_keys;

    for my $foreign_key (@foreign_keys) {
        my $source_table = $foreign_key->source_table();
        my $target_table = $foreign_key->target_table();

        next unless $source_table->name() eq $table->name();

        push @target_keys, $foreign_key;

        my $target_attribute = $self->meta()->get_attribute($target_table->name());
        my $target_reader = $target_attribute->get_read_method();

        push @target_objects, @{$self->$target_reader()};
    }

    my @implant_records = @{$self->get_objects_for_category($table->name())}; 

    for my $implant_record (@implant_records) {
        my %initial_values = %{$implant_record->properties()};   

        my %implant_references;

        for my $key (keys %initial_values) { 
            my ($referenced_table_name, $referenced_field_name) = $key =~ /^(.+)\.(.+)$/;
            
            next unless $referenced_table_name && $referenced_field_name;

            my $referenced_table = $self->schema()->table($referenced_table_name);

            die "bad relation definition $key, table $referenced_table_name can't be looked up\n" unless $referenced_table;
             
            die "bad relation definition $key, table $referenced_table_name doesn't have candidate key $referenced_field_name\n" unless $referenced_table->has_candidate_key($referenced_field_name); 

            $implant_references{$referenced_table_name}->{$referenced_field_name} = $initial_values{$key};
        }

        for my $foreign_key (@target_keys) {
            my $target_table = $foreign_key->target_table();
            my @column_pairs_set = $foreign_key->column_pairs();

            my $target_object = undef;

            my $target_table_name = $target_table->name();
            
            for my $column_pairs_set (@column_pairs_set) {
                for my $column_pairs (@$column_pairs_set) {
                    my ($source_column, $target_column) = @$column_pairs;

                    my $source_column_name = $source_column->name();
                    my $target_column_name = $target_column->name();

                    for my $implant_reference (keys %implant_references) {
                        for my $implant_target_column (keys %{$implant_references{$target_table_name}}) {
                            for my $target_object (@target_objects) { 
                                my $target_parameter_name = "$target_table_name.$implant_target_column";

				next unless $target_object->can($implant_target_column) && defined $target_object->$implant_target_column();

                                next unless $initial_values{$target_parameter_name};

                                next unless $target_object->$implant_target_column() eq $initial_values{$target_parameter_name};

                                $initial_values{$source_column_name} = $target_object->$target_column_name();  
    
                                delete $initial_values{$target_parameter_name}; 
                            }
                        }  
                    }
                }
            }
        }

        my $new_object = undef;

        if ($new_object = $class_name->new(%initial_values)) {
            $new_object->update(%initial_values);

            #TODO: clear out child objects       
            $self->_delete_child_records($new_object); 
        }
        else {
            $new_object = $class_name->insert(%initial_values);
        }

        push(@objects, $new_object);
    }

    return \@objects;
}

sub _implant_objects {
    my ($self, $objects) = @_;

    my %object_map; 

    for my $object (@$objects) {
        push @{$object_map{$object->category()}}, $object;
    }

    $self->object_map(\%object_map);

    for my $category (keys %object_map) {
        $self->$category();
    }

    return 1;
}

sub _delete_child_records {
    my ($self, $object) = @_;

    my $table = $object->Table();

    my @foreign_keys = $table->schema()->foreign_keys_for_table($table);

    my @source_keys;

    for my $foreign_key (@foreign_keys) {
        my $target_table = $foreign_key->target_table();
        my $source_table = $foreign_key->source_table();

        next if $source_table->name() eq $table->name();

        push @source_keys, $foreign_key;
    }

    for my $source_key (@source_keys) {
        my $query = $self->schema_class()->SQLFactoryClass()->new_select();

        $query->select($source_key->source_table());

        $query->from($source_key->source_table(), $source_key->target_table(), $source_key);

        my $primary_keys = $source_key->target_table()->primary_key();

        for my $primary_key (@$primary_keys) {
            my $primary_key_name = $primary_key->name();
            $query->where($primary_key, '=', $object->$primary_key_name());
        }

        #TODO: allow the source to be passed along as an argument.
        my $dbh = $self->schema_class->DBIManager()->default_source()->dbh();
   
        my $record_set = Fey::Object::Iterator::FromSelect->new(
                                                                classes     => [ (Fey::Meta::Class::Table->ClassForTable( $source_key->source_table() )) ],
                                                                select      => $query,
                                                                dbh         => $dbh
                                                               );

        while (my $record = $record_set->next()) {
            $self->_delete_child_records($record);            

            $record->delete();
        }
    }
}

sub _delete_child_objects {
    my ($self, $module_name) = @_;

    my $attribute = $self->meta->get_attribute($module_name);

    return undef unless $attribute;

    my $table = Callusion::Model::Schema->Schema()->table($module_name);

    my $predicate = $attribute->predicate();
    return undef unless $self->$predicate();

    my @foreign_keys = $table->schema()->foreign_keys_for_table($table);

    for my $foreign_key (@foreign_keys) {
        my $source_table = $foreign_key->source_table();
        my $target_table = $foreign_key->target_table();

        next if $target_table->name() ne $table->name();

        $self->_delete_objects($source_table->name());
    }

    for my $object (@{$self->$module_name}) {
        $object->delete();
    }

    my $clearer = $attribute->clearer();
    $self->$clearer();

    return undef;
}

no Fey;
no Moose;

1;
