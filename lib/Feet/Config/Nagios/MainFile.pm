package Nagios::Config::Main;

use Moose;

use MooseX::AttributeHelpers;

use Nagios::Config::ObjectFile;

with 'Nagios::Config::File';

has +new_file => ( is => 'ro', init_args => undef );

has cfg_dirs => (
    metaclass => 'Collection::Array',
    isa => 'ArrayRef[Str]',
    is  => 'rw',
    lazy => 1,
    builder => '_build_objects',
    trigger => sub { my $self = shift; $self->clear_object_files() },
    required => 1,
    provides => {
                 'get'           => 'get_cfgdir_at',
                 'count'         => 'num_cfgdirs',
                 'empty'         => 'has_cfgdirs',
                 'sort_in_place' => 'sort_cfgdirs',
                 },
);

#sub add_cfgdir {
#     my ($self, $dir_name) = @_;
#
#     my @files = grep { $_ =~ /^(\w+)\.cfg$/ } readdir $dir_name or die "unable to create directory";  
#
#     for my $file (@files) {
#         $self->set_objectfile($1, Nagios::Object::File->new( file_name => $current_file) );
#     }
#
#     return 1;
#}; 

#sub del_cfgdir {
#    my ($self, $dir_name) = @_;
#
#    for my $object_file (readdir($dir_name)) {
#        $self->delete_object_file($object_file);
#    }
#         
#    rmdir $dir_name;
#}

# coerce into an object file object, just the file name should be needed
has object_files => (
    metaclass => 'Collection::Hash',
    isa => 'HashRef[Nagios::Config::ObjectFile]',
    is  => 'rw',
    lazy => 1,
    builder => '_build_object_files',
    required => 1,
    trigger => sub { my $self = shift; $self->clear_objects(); },
    provides => {
                 set    => 'set_object_file',
                 get    => 'get_object_file',
                 empty  => 'has_objects_file',
                 count  => 'num_objects_file',
                 clear  => 'clear_object_files',
                 exists => 'has_objectfiles',
    },
);

sub _build_object_files {
    my ($self) = @_;

    my %object_files;

    for my $cfg_dir (@{$self->config_dirs}) { 
        my @files = readdir $cfg_dir or die "unable to create directory";
        
        for my $file (@files) {
           my ($file_prefix) = $file =~ /^(\w+)\.cfg$/;
            
           next unless $file_prefix;         

           $object_files{$file_prefix} = Nagios::ObjectFile->new($file);
        } 
    }

    return \%object_files;
}

#sub delete_object_file {
#    my ($self, $file_name) = @_;
#
#    for my $object ($self->objects()) {
#        $self->delete_object($object->name());
#    }
#
#    delete $self->object_files->{$file_name};
#
#    return 1;
#}

#has objects => (
#    metaclass => 'Collection::Hash',
#    isa => 'HashRef[Nagios::Object]',
#    is  => 'rw',
#    provides => {
#                 set    => 'set_object',
#                 get    => 'get_object',
#                 empty  => 'has_objects',
#                 count  => 'num_objects',
#                 clear  => 'clear_objects',
#                 delete => 'delete_objects',
#                 exists => 'has_object',
#    },
#);
#
#sub _build_objects {
#    my ($self) = @_;
#
#    my %objects;
#
#    for my $object_file ($self->object_files()) {
#        for my $object ($object_file->objects()) {
#             $objects{$object_file->object_type() . "/" . $object->name()} = $object;
#        }
#    }
#
#    return \%objects;
#}

# LOG FILE
has log_file => ( isa => 'Str', is => 'rw', documentation => 'This is the main log file where service and host events are logged for historical purposes.  This should be the first option specified in the config file!!!' );

# OBJECT CACHE FILE
has object_cache_file => ( isa => 'Str', is => 'rw', documentation => 'This option determines where object definitions are cached when Nagios starts/restarts.  The CGIs read object definitions from this cache file (rather than looking at the object config files directly) in order to prevent inconsistencies that can occur when the config files are modified after Nagios starts.');

# PRE-CACHED OBJECT FILE
has precached_object_file => ( isa => 'Str', is => 'rw', documentation => 'This options determines the location of the precached object file. If you run Nagios with the -p command line option, it will preprocess your object configuration file(s) and write the cached config to this file.  You can then start Nagios with the -u option to have it read object definitions from this precached file, rather than the standard object configuration files (see the cfg_file and cfg_dir options above). Using a precached object file can speed up the time needed to (re)start the Nagios process if you\'ve got a large and/or complex configuration. Read the documentation section on optimizing Nagios to find our more about how this feature works.' );

# RESOURCE FILE
has resource_file => ( isa => 'Str', is => 'rw', documentation => 'This is an optional resource file that contains $USERx$ macro definitions. Multiple resource files can be specified by using multiple resource_file definitions.  The CGIs will not attempt to read the contents of resource files, so information that is considered to be sensitive (usernames, passwords, etc) can be defined as macros in this file and restrictive permissions (600) can be placed on this file.' );

# STATUS FILE
has status_file => ( isa => 'Str', is => 'rw', documentation => 'This is where the current status of all monitored services and hosts is stored.  Its contents are read and processed by the CGIs. The contents of the status file are deleted every time Nagios restarts.' );

# STATUS FILE UPDATE INTERVAL
has status_update_interval => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option determines the frequency (in seconds) that Nagios will periodically dump program, host, and service status data.' );

# NAGIOS USER
has nagios_user => ( isa => 'Str', is => 'rw', documentation => 'This determines the effective user that Nagios should run as. You can either supply a username or a UID.' );

# NAGIOS GROUP
has nagios_group => ( isa => 'Str', is => 'rw', documentation => 'This determines the effective group that Nagios should run as. You can either supply a group name or a GID.' );

# EXTERNAL COMMAND OPTION
has check_external_command => ( isa => 'Nagios::Object::Command', is => 'rw', documentation => 'This option allows you to specify whether or not Nagios should check for external commands (in the command file defined below).  By default Nagios will *not* check for external commands, just to be on the cautious side.  If you want to be able to use the CGI command interface you will have to enable this. Values: 0 = disable commands, 1 = enable commands' );

# EXTERNAL COMMAND CHECK INTERVAL
has command_check_interval => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This is the interval at which Nagios should check for external commands. This value works of the interval_length you specify later.  If you leave that at its default value of 60 (seconds), a value of 1 here will cause Nagios to check for external commands every minute.  If you specify a number followed by an "s" (i.e. 15s), this will be interpreted to mean actual seconds rather than a multiple of the interval_length variable. Note: In addition to reading the external command file at regularly scheduled intervals, Nagios will also check for external commands after event handlers are executed. NOTE: Setting this value to -1 causes Nagios to check the external command file as often as possible.' );

# EXTERNAL COMMAND FILE
has command_file => ( isa => 'Str', is => 'rw', documentation => 'This is the file that Nagios checks for external command requests. It is also where the command CGI will write commands that are submitted by users, so it must be writeable by the user that the web server is running as (usually nobody). Permissions should be set at the directory level instead of on the file, as the file is deleted every time its contents are processed.' );

# EXTERNAL COMMAND BUFFER SLOTS
has external_command_buffer_slots => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This settings is used to tweak the number of items or "slots" that the Nagios daemon should allocate to the buffer that holds incoming external commands before they are processed.  As external commands are processed by the daemon, they are removed from the buffer.' );

# LOCK FILE
has lock_file => ( isa => 'Str', is => 'rw', documentation => 'This is the lockfile that Nagios will use to store its PID number in when it is running in daemon mode.' );

# TEMP FILE
has temp_file => ( isa => 'Str', is => 'rw', documentation => 'This is a temporary file that is used as scratch space when Nagios updates the status log, cleans the comment file, etc.  This file is created, used, and deleted throughout the time that Nagios is running.' );

# TEMP PATH
has temp_path => ( isa => 'Str', is => 'rw', documentation => 'This is path where Nagios can create temp files for service and host check results, etc.');

# EVENT BROKER OPTIONS
has event_broker_options => ( isa => 'Int', is => 'rw', documentation => 'Controls what (if any) data gets sent to the event broker. Values:  0 = Broker nothing, -1 = Broker everything, <other> = See documentation' );

# LOG ROTATION METHOD
has log_rotation_method => ( isa => 'Str', where => { $_ =~ /^(n|h|d|w|m)$/ }, is => 'rw', documentation => 'This is the log rotation method that Nagios should use to rotate the main log file. Values: n	= None - don\'t rotate the log, h = Hourly rotation (top of the hour), d = Daily rotation (midnight every day), w = Weekly rotation (midnight on Saturday evening), m = Monthly rotation (midnight last day of month)' );

# LOG ARCHIVE PATH
has log_archive_path => ( isa => 'Str', is => 'rw', documentation => 'This is the directory where archived (rotated) log files should be placed (assuming you\'ve chosen to do log rotation).' );

# LOGGING OPTIONS
has use_syslog => ( isa => 'Bool', is => 'rw', documentation => 'If you want messages logged to the syslog facility, as well as the Nagios log file set this option to 1.  If not, set it to 0.' );

# NOTIFICATION LOGGING OPTION
has log_notifications => ( isa => 'Bool', is => 'rw', documentation => 'If you don\'t want notifications to be logged, set this value to 0. If notifications should be logged, set the value to 1.' );

# SERVICE RETRY LOGGING OPTION
has log_service_retries => ( isa => 'Bool', is => 'rw', documentation => 'If you don\'t want service check retries to be logged, set this value to 0.  If retries should be logged, set the value to 1.');

# HOST RETRY LOGGING OPTION
has log_host_retries => ( isa => 'Bool', is => 'rw', documentation => 'If you don\'t want host check retries to be logged, set this value to 0.  If retries should be logged, set the value to 1.');

# EVENT HANDLER LOGGING OPTION
has log_event_handlers => ( isa => 'Bool', is => 'rw', documentation => 'If you don\'t want host and service event handlers to be logged, set this value to 0.  If event handlers should be logged, set the value to 1.');

# INITIAL STATES LOGGING OPTION
has log_initial_states => ( isa => 'Bool', is => 'rw', documentation => 'If you want Nagios to log all initial host and service states to the main log file (the first time the service or host is checked) you can enable this option by setting this value to 1. If you are not using an external application that does long term state statistics reporting, you do not need to enable this option.  In this case, set the value to 0.');

# EXTERNAL COMMANDS LOGGING OPTION
has log_external_commands => ( isa => 'Bool', is => 'rw', documentation => 'If you don\'t want Nagios to log external commands, set this value to 0. If external commands should be logged, set this value to 1. Note: This option does not include logging of passive service checks - see the option below for controlling whether or not passive checks are logged.');

# PASSIVE CHECKS LOGGING OPTION
has log_passive_checks => ( isa => 'Bool', is => 'rw', documentation => 'If you don\'t want Nagios to log passive host and service checks, set this value to 0.  If passive checks should be logged, set this value to 1.');

# GLOBAL HOST EVENT HANDLER
has global_host_event_handler => ( isa => 'Nagios::Object::Command', is => 'rw', documentation => 'These options allow you to specify a host event handler command that is to be run for every host state change. The global event handler is executed immediately prior to the event handler that you have optionally specified in each host definition. The command argument is the short name of a command definition that you define in your host configuration file. Read the HTML docs for more information.' );

# GLOBAL SERVICE EVENT HANDLER
has global_service_event_handler => ( isa => 'Nagios::Object::Command', is => 'rw', documentation => 'These options allow you to specify a service event handler command that is to be run for every service state change. The global event handler is executed immediately prior to the event handler that you have optionally specified in each service definition. The command argument is the short name of a command definition that you define in your service configuration file. Read the HTML docs for more information.' );

# SERVICE INTER-CHECK DELAY METHOD
has service_inter_check_delay_method => ( isa => 'Str', where => { $_ =~ /^(n|d|s|\d\.\d{1,2})$/ }, is => 'rw', documentation => 'This is the method that Nagios should use when initially "spreading out" service checks when it starts monitoring.  The default is to use smart delay calculation, which will try to space all service checks out evenly to minimize CPU load. Using the dumb setting will cause all checks to be scheduled at the same time (with no delay between them)!  This is not a good thing for production, but is useful when testing the parallelization functionality. Values: n = None - don\'t use any delay between checks, d = Use a "dumb" delay of 1 second between checks, s = Use "smart" inter-check delay calculation, x.xx = Use an inter-check delay of x.xx seconds' );

# MAXIMUM SERVICE CHECK SPREAD
has max_service_check_spread => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This variable determines the timeframe (in minutes) from the program start time that an initial check of all services should be completed.  Default is 30 minutes.' );

# SERVICE CHECK INTERLEAVE FACTOR
has service_interleave_factor => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This variable determines how service checks are interleaved. Interleaving the service checks allows for a more even distribution of service checks and reduced load on remote hosts.  Setting this value to 1 is equivalent to how versions of Nagios previous to 0.0.5 did service checks.  Set this value to s (smart) for automatic calculation of the interleave factor unless you have a specific reason to change it. Values: s = Use "smart" interleave factor calculation, x = Use an interleave factor of x, where x is a number greater than or equal to 1.' );

# HOST INTER-CHECK DELAY METHOD
has host_inter_check_delay_method => ( isa => 'Str', where => { $_ =~ /(n|d|s|\d.\d{1,2})/ }, is => 'rw', documentation => 'This is the method that Nagios should use when initially "spreading out" host checks when it starts monitoring.  The default is to use smart delay calculation, which will try to space all host checks out evenly to minimize CPU load. Using the dumb setting will cause all checks to be scheduled at the same time (with no delay between them)! Values: n = None - don\'t use any delay between checks, d = Use a "dumb" delay of 1 second between checks, s = Use "smart" inter-check delay calculation, x.xx = Use an inter-check delay of x.xx seconds' );

# MAXIMUM HOST CHECK SPREAD
has max_host_check_spread => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This variable determines the timeframe (in minutes) from the program start time that an initial check of all hosts should be completed.  Default is 30 minutes.' );

# MAXIMUM CONCURRENT SERVICE CHECKS
has max_concurrent_checks => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option allows you to specify the maximum number of service checks that can be run in parallel at any given time. Specifying a value of 1 for this variable essentially prevents any service checks from being parallelized.  A value of 0 will not restrict the number of concurrent checks that are being executed.' );

# HOST AND SERVICE CHECK REAPER FREQUENCY
has check_result_reaper_frequency => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This is the frequency (in seconds!) that Nagios will process the results of host and service checks.' );

# MAX CHECK RESULT REAPER TIME
has max_check_results_reaper_time => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This is the max amount of time (in seconds) that  a single check result reaper event will be allowed to run before  returning control back to Nagios so it can perform other duties.' );

# CHECK RESULT PATH
has check_result_path => ( isa => 'Str', is => 'rw', documentation => 'This is directory where Nagios stores the results of host and service checks that have not yet been processed. Note: Make sure that only one instance of Nagios has access to this directory!' );

# MAX CHECK RESULT FILE AGE
has max_check_result_file_age => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option determines the maximum age (in seconds) which check result files are considered to be valid.  Files older than this  threshold will be mercilessly deleted without further processing.' );

# CACHED HOST CHECK HORIZON
has cached_host_check_horizon => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option determines the maximum amount of time (in seconds) that the state of a previous host check is considered current. Cached host states (from host checks that were performed more recently that the timeframe specified by this value) can immensely improve performance in regards to the host check logic. Too high of a value for this option may result in inaccurate host states being used by Nagios, while a lower value may result in a performance hit for host checks. Use a value of 0 to disable host check caching.' );

# CACHED SERVICE CHECK HORIZON
has cached_service_check_horizon => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option determines the maximum amount of time (in seconds) that the state of a previous service check is considered current. Cached service states (from service checks that were performed more recently that the timeframe specified by this value) can immensely improve performance in regards to predictive dependency checks. Use a value of 0 to disable service check caching.' );

# ENABLE PREDICTIVE HOST DEPENDENCY CHECKS
has enable_predictive_host_dependency_checks => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will attempt to execute checks of hosts when it predicts that future dependency logic test may be needed.  These predictive checks can help ensure that your host dependency logic works well. Values: 0 = Disable predictive checks, 1 = Enable predictive checks (default)');

# ENABLE PREDICTIVE SERVICE DEPENDENCY CHECKS
has enable_predictive_service_dependency_checks => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will attempt to execute checks of service when it predicts that future dependency logic test may be needed.  These predictive checks can help ensure that your service dependency logic works well. Values: 0 = Disable predictive checks, 1 = Enable predictive checks (default)' );

# SOFT STATE DEPENDENCIES
has soft_state_dependencies => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will use soft state information when checking host and service dependencies. Normally  Nagios will only use the latest hard host or service state when checking dependencies. If you want it to use the latest state (regardless of whether its a soft or hard state type), enable this option. Values: 0 = Don\'t use soft state dependencies (default), 1 = Use soft state dependencies' );

# TIME CHANGE ADJUSTMENT THRESHOLDS
#TODO: determine proper type
has time_change_threshold => ( isa => 'Str', is => 'rw', documentation => 'These options determine when Nagios will react to detected changes in system time (either forward or backwards).' );

# AUTO-RESCHEDULING OPTION
has auto_reschedule_checks => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will attempt to automatically reschedule active host and service checks to "smooth" them out over time.  This can help balance the load on the monitoring server. WARNING: THIS IS AN EXPERIMENTAL FEATURE - IT CAN DEGRADE PERFORMANCE, RATHER THAN INCREASE IT, IF USED IMPROPERLY');

# AUTO-RESCHEDULING INTERVAL
has auto_rescheduling_interval => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option determines how often (in seconds) Nagios will attempt to automatically reschedule checks.  This option only has an effect if the auto_reschedule_checks option is enabled. Default is 30 seconds. WARNING: THIS IS AN EXPERIMENTAL FEATURE - IT CAN DEGRADE PERFORMANCE, RATHER THAN INCREASE IT, IF USED IMPROPERLY' );

# AUTO-RESCHEDULING WINDOW
has auto_rescheduling_window => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option determines the "window" of time (in seconds) that Nagios will look at when automatically rescheduling checks. Only host and service checks that occur in the next X seconds (determined by this variable) will be rescheduled. This option only has an effect if the auto_reschedule_checks option is enabled.  Default is 180 seconds (3 minutes). WARNING: THIS IS AN EXPERIMENTAL FEATURE - IT CAN DEGRADE PERFORMANCE, RATHER THAN INCREASE IT, IF USED IMPROPERLY' );

# SLEEP TIME
has sleep_time => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This is the number of seconds to sleep between checking for system events and service checks that need to be run.' );

# SERVICE CHECK TIMEOUT VALUES
has service_check_timeout => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option controls how much time Nagios will allow service checks to to execute before killing it off. This value should be given in seconds.' );

# HOST CHECK TIMEOUT VALUES
has host_check_timeout => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option controls how much time Nagios will allow host checks to to execute before killing it off. This value should be given in seconds.' );

# EVENT HANDLER TIMEOUT VALUES
has event_handler_timeout => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option controls how much time Nagios will allow event handlers to to execute before killing it off. This value should be given in seconds.' );

# NOTIFICATION TIMEOUT
has notification_timeout => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option controls how much time Nagios will allow nofitications to to execute before killing it off. This value should be given in seconds.' );

# OSCP TIMEOUT
has oscp_timeout => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option controls how much time Nagios will allow oscp checks to to execute before killing it off. This value should be given in seconds.' );

# PERFDATA TIMEOUT
has perfdata_timeout => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option controls how much time Nagios will allow performance data checks to to execute before killing it off. This value should be given in seconds.' );

# RETAIN STATE INFORMATION
has retain_state_information => ( isa => 'Bool', is => 'rw', documentation => 'This setting determines whether or not Nagios will save state information for services and hosts before it shuts down.  Upon startup Nagios will reload all saved service and host state information before starting to monitor.  This is useful for maintaining long-term data on state statistics, etc, but will slow Nagios down a bit when it (re)starts.  Since its only a one-time penalty, I think its well worth the additional startup delay.' );

# STATE RETENTION FILE
has state_retention_file => ( isa => 'Str', is => 'rw', documentation => 'This is the file that Nagios should use to store host and service state information before it shuts down.  The state  information in this file is also read immediately prior to starting to monitor the network when Nagios is restarted. This file is used only if the preserve_state_information variable is set to 1.' );

# RETENTION DATA UPDATE INTERVAL
has retention_update_interval => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This setting determines how often (in minutes) that Nagios will automatically save retention data during normal operation. If you set this value to 0, Nagios will not save retention data at regular interval, but it will still save retention data before shutting down or restarting.  If you have disabled state retention, this option has no effect.' );

# USE RETAINED PROGRAM STATE
has use_retained_program_state => ( isa => 'Bool', is => 'rw', documentation => 'This setting determines whether or not Nagios will set program status variables based on the values saved in the retention file.  If you want to use retained program status information, set this value to 1. If not, set this value to 0.' );

# USE RETAINED SCHEDULING INFO
has use_retained_scheduling_info => ( isa => 'Bool', is => 'rw', documentation => 'This setting determines whether or not Nagios will retain the scheduling info (next check time) for hosts and services based on the values saved in the retention file.  If you If you want to use retained scheduling info, set this value to 1.  If not, set this value to 0.' );

# RETAINED ATTRIBUTE MASKS (ADVANCED FEATURE)
has retained_host_attribute_mask => ( isa => 'Str', is => 'rw', documentation => 'This variable is used to specify specific host attributes that should *not* be retained by Nagios during program restarts. The values of this masks is bitwise ANDs of values specified by the "MODATTR_" definitions found in include/common.h. For example, if you do not want the current enabled/disabled state of flap detection and event handlers for hosts to be retained, you would use a value of 24 for the host attribute mask... MODATTR_EVENT_HANDLER_ENABLED (8) + MODATTR_FLAP_DETECTION_ENABLED (16) = 24' );

has retained_service_attribute_mask => ( isa => 'Str', is => 'rw', documentation => 'This variables is used to specify specific service attributes that should *not* be retained by Nagios during program restarts. The values of this masks is bitwise ANDs of values specified by the "MODATTR_" definitions found in include/common.h. For example, if you do not want the current enabled/disabled state of flap detection and event handlers for hosts to be retained, you would use a value of 24 for the host attribute mask... MODATTR_EVENT_HANDLER_ENABLED (8) + MODATTR_FLAP_DETECTION_ENABLED (16) = 24' );

has retained_contact_host_attribute_mask => ( isa => 'Str', is => 'rw', documentation => 'This mask determines what host-specific contact attributes are not retained.' );

has retained_contact_service_attribute_mask => ( isa => 'Str', is => 'rw', documentation => 'This mask determines what service-specific contact attributes are not retained.' );

# INTERVAL LENGTH
has interval_length => ( isa => 'Int', where => { $_ > 0 },isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This is the seconds per unit interval as used in the host/contact/service configuration files.  Setting this to 60 means that each interval is one minute long (60 seconds).  Other settings have not been tested much, so your mileage is likely to vary...' );

# AGGRESSIVE HOST CHECKING OPTION
has use_aggressive_host_checking => ( isa => 'Bool', is => 'rw', documentation => 'If you don\'t want to turn on aggressive host checking features, set this value to 0 (the default).  Otherwise set this value to 1 to enable the aggressive check option.  Read the docs for more info on what aggressive host check is or check out the source code in base/checks.c' );

# SERVICE CHECK EXECUTION OPTION
has execute_service_checks => ( isa => 'Bool', is => 'rw', documentation => 'This determines whether or not Nagios will actively execute service checks when it initially starts.  If this option is disabled, checks are not actively made, but Nagios can still receive and process passive check results that come in.  Unless you\'re implementing redundant hosts or have a special need for disabling the execution of service checks, leave this enabled! Values: 1 = enable checks, 0 = disable checks' );

# PASSIVE SERVICE CHECK ACCEPTANCE OPTION
has accept_passive_service_checks => ( isa => 'Bool', is => 'rw', documentation => 'This determines whether or not Nagios will accept passive service checks results when it initially (re)starts. Values: 1 = accept passive checks, 0 = reject passive checks' );

# HOST CHECK EXECUTION OPTION
has execute_host_checks => ( isa => 'Bool', is => 'rw', documentation => 'This determines whether or not Nagios will actively execute host checks when it initially starts.  If this option is  disabled, checks are not actively made, but Nagios can still receive and process passive check results that come in.  Unless you\'re implementing redundant hosts or have a special need for disabling the execution of host checks, leave this enabled! Values: 1 = enable checks, 0 = disable checks' );

# PASSIVE HOST CHECK ACCEPTANCE OPTION
has accept_passive_host_checks => ( isa => 'Bool', is => 'rw', documentation => 'This determines whether or not Nagios will accept passive host checks results when it initially (re)starts. Values: 1 = accept passive checks, 0 = reject passive checks' );

# NOTIFICATIONS OPTION
has enable_notifications => ( isa => 'Bool', is => 'rw', documentation => 'This determines whether or not Nagios will sent out any host or service notifications when it is initially (re)started. Values: 1 = enable notifications, 0 = disable notifications' );

# EVENT HANDLER USE OPTION
has enable_event_handlers => ( isa => 'Bool', is => 'rw', documentation => 'This determines whether or not Nagios will run any host or service event handlers when it is initially (re)started.  Unless you\'re implementing redundant hosts, leave this option enabled. Values: 1 = enable event handlers, 0 = disable event handlers' );

# PROCESS PERFORMANCE DATA OPTION
has process_performance_data => ( isa => 'Bool', is => 'rw', documentation => 'This determines whether or not Nagios will process performance data returned from service and host checks.  If this option is enabled, host performance data will be processed using the host_perfdata_command (defined below) and service performance data will be processed using the service_perfdata_command (also defined below). Read the HTML docs for more information on performance data. Values: 1 = process performance data, 0 = do not process performance data' );

# HOST AND SERVICE PERFORMANCE DATA PROCESSING COMMANDS
has host_perfdata_command => ( isa => 'Nagios::Object::Command', is => 'rw', documentation => 'This command is run after every host check is performed. This command is executed only if the enable_performance_data option is set to 1.  The command argument is the short name of a command definition that you define in your host configuration file. Read the HTML docs for more information on performance data.' );

has service_perfdata_command => ( isa => 'Nagios::Object::Command', is => 'rw', documentation => 'This command is run after every service check is performed. This command is executed only if the enable_performance_data option is set to 1.  The command argument is the short name of a command definition that you define in your service configuration file. Read the HTML docs for more information on performance data.' );

# HOST AND SERVICE PERFORMANCE DATA FILES
has host_perfdata_file => ( isa => 'Str', is => 'rw', documentation => 'This file is used to store host performance data. Performance data is only written to this files if the enable_performance_data option is set to 1.' );

has service_perfdata_file => ( isa => 'Str', is => 'rw', documentation => 'This file is used to store service performance data. Performance data is only written to this files if the enable_performance_data option is set to 1.' );

# HOST AND SERVICE PERFORMANCE DATA FILE TEMPLATES
has host_perfdata_file_template => ( isa => 'Str', is => 'rw', documentation => 'This option determine what data is written (and how) to the host performance data file.  The template may contain macros, special characters (\t for tab, \r for carriage return, \n for newline) and plain text.  A newline is automatically added after each write to the performance data file. See documentation for examples of what you can do are shown below.' );

has service_perfdata_file_template => ( isa => 'Str', is => 'rw', documentation => 'This option determine what data is written (and how) to the service performance data file.  The template may contain macros, special characters (\t for tab, \r for carriage return, \n for newline) and plain text.  A newline is automatically added after each write to the performance data file. See documentation for examples of what you can do are shown below.' );

# HOST AND SERVICE PERFORMANCE DATA FILE MODES
has host_perfdata_file_mode => ( isa => 'Str', is => 'rw', documentation => 'This option determines whether or not the host performance data file is opened in write ("w") or append ("a") mode. If you want to use named pipes, you should use the special pipe ("p") mode which avoid blocking at startup, otherwise you will likely want the defult append ("a") mode.' );

has service_perfdata_file_mode => ( isa => 'Str', where => { $_ =~ /^(a|w|p)$/ },  is => 'rw', documentation => 'This option determines whether or not the service performance data file is opened in write ("w") or append ("a") mode. If you want to use named pipes, you should use the special pipe ("p") mode which avoid blocking at startup, otherwise you will likely want the defult append ("a") mode.' );

# HOST AND SERVICE PERFORMANCE DATA FILE PROCESSING INTERVAL
has host_perfdata_file_processing_interval => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option determines how often (in seconds) the host performance data file is processed using the commands defined below.  A value of 0 indicates the files should not be periodically processed.' );

has service_perfdata_file_processing_interval => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option determines how often (in seconds) the service performance data file is processed using the commands defined below.  A value of 0 indicates the files should not be periodically processed.' );

# HOST AND SERVICE PERFORMANCE DATA FILE PROCESSING COMMANDS
has host_perfdata_file_processing_command => ( isa => 'Nagios::Object::Command', is => 'rw', documentation => 'This command is used to periodically process the host performance data file.' );

has service_perfdata_file_processing_command => ( isa => 'Nagios::Object::Command', is => 'rw', documentation => 'This command is used to periodically process the service performance data file.' );

# OBSESS OVER SERVICE CHECKS OPTION
has obsess_over_services => ( isa => 'Bool', is => 'rw', documentation => 'This determines whether or not Nagios will obsess over service checks and run the ocsp_command defined below.  Unless you\'re planning on implementing distributed monitoring, do not enable this option.  Read the HTML docs for more information on implementing distributed monitoring. Values: 1 = obsess over services, 0 = do not obsess (default)' );

# OBSESSIVE COMPULSIVE SERVICE PROCESSOR COMMAND
has ocsp_command => ( isa => 'Nagios::Object::Command', is => 'rw', documentation => 'This is the command that is run for every service check that is processed by Nagios.  This command is executed only if the obsess_over_services option (above) is set to 1.  The command argument is the short name of a command definition that you define in your host configuration file. Read the HTML docs for more information on implementing distributed monitoring.' );

# OBSESS OVER HOST CHECKS OPTION
has obsess_over_host => ( isa => 'Bool', is => 'rw', documentation => 'This determines whether or not Nagios will obsess over host checks and run the ochp_command defined below.  Unless you\'re planning on implementing distributed monitoring, do not enable this option.  Read the HTML docs for more information on implementing distributed monitoring. Values: 1 = obsess over hosts, 0 = do not obsess (default)');

# OBSESSIVE COMPULSIVE HOST PROCESSOR COMMAND
has ochp_command => ( isa => 'Nagios::Object::Command', is => 'rw', documentation => 'This is the command that is run for every host check that is processed by Nagios.  This command is executed only if the obsess_over_hosts option (above) is set to 1.  The command  argument is the short name of a command definition that you define in your host configuration file. Read the HTML docs for more information on implementing distributed monitoring.' );

# TRANSLATE PASSIVE HOST CHECKS OPTION
has translate_passive_host_checks => ( isa => 'Bool', is => 'rw', documentation => 'This determines whether or not Nagios will translate DOWN/UNREACHABLE passive host check results into their proper state for this instance of Nagios.  This option is useful if you have distributed or failover monitoring setup.  In these cases your other Nagios servers probably have a different "view" of the network, with regards to the parent/child relationship of hosts.  If a distributed monitoring server thinks a host is DOWN, it may actually be UNREACHABLE from the point of this Nagios instance.  Enabling this option will tell Nagios to translate any DOWN or UNREACHABLE host states it receives passively into the correct state from the view of this server. Values: 1 = perform translation, 0 = do not translate (default)' );

# PASSIVE HOST CHECKS ARE SOFT OPTION
has passive_host_checks_are_soft => ( isa => 'Bool', is => 'rw', documentation => 'This determines whether or not Nagios will treat passive host checks as being HARD or SOFT.  By default, a passive host check result will put a host into a HARD state type.  This can be changed by enabling this option. Values: 0 = passive checks are HARD, 1 = passive checks are SOFT' );

# ORPHANED HOST/SERVICE CHECK OPTIONS
has check_for_orphaned_hosts => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will periodically check for orphaned host checks. Orphaned checks seem to be a rare problem and should not happen under normal circumstances. If you have problems with service checks never getting rescheduled, make sure you have orphaned service checks enabled. Values: 1 = enable checks, 0 = disable checks' );

has check_for_orphaned_services => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will periodically check for orphaned service checks. Orphaned checks seem to be a rare problem and should not happen under normal circumstances. If you have problems with service checks never getting rescheduled, make sure you have orphaned service checks enabled. Values: 1 = enable checks, 0 = disable checks' );

# SERVICE FRESHNESS CHECK OPTION
has check_service_freshness => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will periodically check the "freshness" of service results.  Enabling this option is useful for ensuring passive checks are received in a timely manner. Values: 1 = enabled freshness checking, 0 = disable freshness checking' );

# SERVICE FRESHNESS CHECK INTERVAL
has service_freshness_check_interval => ( isa => 'Str', is => 'rw', documentation => 'This setting determines how often (in seconds) Nagios will check the "freshness" of service check results.  If you have disabled service freshness checking, this option has no effect.' );

# HOST FRESHNESS CHECK OPTION
has check_host_freshness => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will periodically check the "freshness" of host results.  Enabling this option is useful for ensuring passive checks are received in a timely manner. Values: 1 = enabled freshness checking, 0 = disable freshness checking' );

# HOST FRESHNESS CHECK INTERVAL
has host_freshness_check_interval => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This setting determines how often (in seconds) Nagios will check the "freshness" of host check results.  If you have disabled host freshness checking, this option has no effect.' );

# ADDITIONAL FRESHNESS THRESHOLD LATENCY
has host_freshness_check_interval => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This setting determines how often (in seconds) Nagios will check the "freshness" of host check results.  If you have disabled host freshness checking, this option has no effect.' );

has additional_freshness_latency => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This setting determines the number of seconds that Nagios will add to any host and service freshness thresholds that it calculates (those not explicitly specified by the user).' );

# FLAP DETECTION OPTION
has enable_flap_detection => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will try and detect hosts and services that are "flapping". Flapping occurs when a host or service changes between states too frequently.  When Nagios detects that a host or service is flapping, it will temporarily suppress notifications for that host/service until it stops flapping.  Flap detection is very experimental, so read the HTML documentation before enabling this feature! Values: 1 = enable flap detection, 0 = disable flap detection (default)' );

# FLAP DETECTION THRESHOLDS FOR HOSTS AND SERVICES
#TODO: determine proper type
has low_service_flap_threshold => ( isa => 'Str', is => 'rw', documentation => 'Read the HTML documentation on flap detection for an explanation of what this option does.  This option has no effect if flap detection is disabled.' );

#TODO: determine proper type
has high_service_flap_threshold => ( isa => 'Str', is => 'rw', documentation => 'Read the HTML documentation on flap detection for an explanation of what this option does.  This option has no effect if flap detection is disabled.' );

#TODO: determine proper type
has low_host_flap_threshold => ( isa => 'Str', is => 'rw', documentation => 'Read the HTML documentation on flap detection for an explanation of what this option does.  This option has no effect if flap detection is disabled.' );

#TODO: determine proper type
has high_host_flap_threshold => ( isa => 'Str', is => 'rw', documentation => 'Read the HTML documentation on flap detection for an explanation of what this option does.  This option has no effect if flap detection is disabled.' );

# DATE FORMAT OPTION
has date_format => ( isa => 'Str', where => { $_ =~ /^(us|euro|iso8601|strict-iso8601)$/ }, is => 'rw', documentation => 'This option determines how short dates are displayed. Valid options include: us (MM-DD-YYYY HH:MM:SS), euro (DD-MM-YYYY HH:MM:SS). iso8601 (YYYY-MM-DD HH:MM:SS), strict-iso8601 (YYYY-MM-DDTHH:MM:SS)' );

# TIMEZONE OFFSET
#TODO: determine proper type
has use_timezone => ( isa => 'Str', is => 'rw', documentation => 'This option is used to override the default timezone that this instance of Nagios runs in.  If not specified, Nagios will use the system configured timezone. NOTE: In order to display the correct timezone in the CGIs, you will also need to alter the Apache directives for the CGI path to include your timezone.' );

# P1.PL FILE LOCATION
#TODO: make directory type 
has p1_file => ( isa => 'Str', is => 'rw', documentation => 'This value determines where the p1.pl perl script (used by the embedded Perl interpreter) is located.  If you didn\'t compile Nagios with embedded Perl support, this option has no effect.' );

# EMBEDDED PERL INTERPRETER OPTION
has enable_embedded_perl => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not the embedded Perl interpreter will be enabled during runtime.  This option has no effect if Nagios has not been compiled with support for embedded Perl. Values: 0 = disable interpreter, 1 = enable interpreter' );

# EMBEDDED PERL USAGE OPTION
has use_embedded_perl_implicitly => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will process Perl plugins and scripts with the embedded Perl interpreter if the plugins/scripts do not explicitly indicate whether or not it is okay to do so. Read the HTML documentation on the embedded Perl interpreter for more information on how this option works.' );

# ILLEGAL OBJECT NAME CHARACTERS
has illegal_object_name_chars => ( isa => 'Str', is => 'rw', documentation => 'This option allows you to specify illegal characters that cannot be used in host names, service descriptions, or names of other object types.' );

# ILLEGAL MACRO OUTPUT CHARACTERS
has illegal_macro_output_chars => ( isa => 'Str', is => 'rw', documentation => 'This option allows you to specify illegal characters that are stripped from macros before being used in notifications, event handlers, etc.  This DOES NOT affect macros used in service or host check commands. The following macros are stripped of the characters you specify: $HOSTOUTPUT$, $HOSTPERFDATA$, $HOSTACKAUTHOR$, $HOSTACKCOMMENT$, $SERVICEOUTPUT$, $SERVICEPERFDATA$, $SERVICEACKAUTHOR$, $SERVICEACKCOMMENT$' );

# REGULAR EXPRESSION MATCHING
has use_regexp_matching => ( isa => 'Bool', is => 'rw', documentation => 'This option controls whether or not regular expression matching takes place in the object config files.  Regular expression matching is used to match host, hostgroup, service, and service group names/descriptions in some fields of various object types. Values: 1 = enable regexp matching, 0 = disable regexp matching' );

# "TRUE" REGULAR EXPRESSION MATCHING
has use_true_regexp_matching => ( isa => 'Bool', is => 'rw', documentation => 'This option controls whether or not "true" regular expression matching takes place in the object config files.  This option only has an effect if regular expression matching is enabled (see above).  If this option is DISABLED, regular expression matching only occurs if a string contains wildcard characters (* and ?).  If the option is ENABLED, regexp matching occurs all the time (which can be annoying). Values: 1 = enable true matching, 0 = disable true matching' );

# ADMINISTRATOR EMAIL/PAGER ADDRESSES
#TODO: make the email type
has admin_email => ( isa => 'Str', is => 'rw', documentation => 'The email address of a global administrator. Nagios never uses these values itself, but you can access them by using the $ADMINEMAIL$ and $ADMINPAGER$ macros in your notification commands.');

#TODO: make the phone number type
has admin_pager => ( isa => 'Str', is => 'rw', documentation => 'The pager number of a global administrator. Nagios never uses these values itself, but you can access them by using the $ADMINEMAIL$ and $ADMINPAGER$ macros in your notification commands.');

# DAEMON CORE DUMP OPTION
has daemon_dumps_core => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios is allowed to create a core dump when it runs as a daemon.  Note that it is generally considered bad form to allow this, but it may be useful for debugging purposes.  Enabling this option doesn\'t guarantee that a core file will be produced, but that\'s just life... Values: 1 - Allow core dumps, 0 - Do not allow core dumps (default)' );

# LARGE INSTALLATION TWEAKS OPTION
has use_large_installation_tweaks => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will take some shortcuts which can save on memory and CPU usage in large Nagios installations. Read the documentation for more information on the benefits/tradeoffs of enabling this option. Values: 1 - Enabled tweaks, 0 - Disable tweaks (default)' );

# ENABLE ENVIRONMENT MACROS
has enable_environment_macros => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will make all standard macros available as environment variables when host/service checks and system commands (event handlers, notifications, etc.) are executed.  Enabling this option can cause performance issues in large installations, as it will consume a bit more memory and (more importantly) consume more CPU. Values: 1 - Enable environment variable macros (default), 0 - Disable environment variable macros' );

# CHILD PROCESS MEMORY OPTION
has free_child_process_memory => ( isa => 'Bool', is => 'rw', documentation => 'This option determines whether or not Nagios will free memory in child processes (processed used to execute system commands and host/service checks).  If you specify a value here, it will override program defaults. Value: 1 - Free memory in child processes, 0 - Do not free memory in child processes' );

# CHILD PROCESS FORKING BEHAVIOR
has child_processes_fork_twice => ( isa => 'Bool', is => 'rw', documentation => 'This option determines how Nagios will fork child processes (used to execute system commands and host/service checks).  Normally child processes are fork()ed twice, which provides a very high level of isolation from problems.  Fork()ing once is probably enough and will save a great deal on CPU usage (in large installs), so you might want to consider using this.  If you specify a value here, it will program defaults. Value: 1 - Child processes fork() twice, 0 - Child processes fork() just once' );

# DEBUG LEVEL
#TODO: determine proper type
has debug_level => ( isa => 'Str', is => 'rw', documentation => 'This option determines how much (if any) debugging information will be written to the debug file.  OR values together to log multiple types of information. Values: -1 = Everything, 0 = Nothing, 1 = Functions, 2 = Configuration, 4 = Process information, 8 = Scheduled events, 16 = Host/service checks, 32 = Notifications, 64 = Event broker, 128 = External commands, 256 = Commands, 512 = Scheduled downtime, 1024 = Comments, 2048 = Macros' );

# DEBUG VERBOSITY
has debug_verbosity => ( isa => 'Bool', is => 'rw', documentation => 'This option determines how verbose the debug log out will be. Values: 0 = Brief output, 1 = More detailed, 2 = Very detailed');

# DEBUG FILE
#TODO: make file type 
has debug_file => ( isa => 'Str', is => 'rw', documentation => 'This option determines where Nagios should write debugging information.' );

# MAX DEBUG FILE SIZE
has host_freshness_check_interval => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This setting determines how often (in seconds) Nagios will check the "freshness" of host check results.  If you have disabled host freshness checking, this option has no effect.' );

has max_debug_file_size => ( isa => 'Int', where => { $_ > 0 }, is => 'rw', documentation => 'This option determines the maximum size (in bytes) of the debug file.  If the file grows larger than this size, it will be renamed with a .old extension.  If a file already exists with a .old extension it will automatically be deleted.  This helps ensure your disk space usage doesn\'t get out of control when debugging Nagios.' );

sub _parse {
    my ($self) = @_;

    for my $line (@{$self->lines()}) {
        chomp $line;

        print "checking line: $line\n";

        my ($key, $value) = split /=/, $line;  
 
        if ($key eq 'cfg_dir') {
            print "adding config dir $value";
            push @{$self->cfg_dirs}, $value;
        }
        elsif ($key eq 'cfg_file') {
            print "adding config file $value";
            $self->set_object_file($value, Nagios::ObjectFile->new($value)); 
        }
        else {
            print "setting $key to $value";
            $self->$key($value);
        }
    }

    return 1;
}

sub BUILD {
    my ($self) = @_;

    $self->_parse();

    print "built main\n";

    return;
}

sub _get_dir_contents {
    my ($self, $dir_name) = @_;

    opendir my ($dh), $dir_name;
    my @contents = grep {$_ =~ /^[^.].*\.cfg$/} readdir $dh or die "unable to open $dir_name: $!\n";
    closedir $dh;

    return @contents;
}

1;
#no Moose;
