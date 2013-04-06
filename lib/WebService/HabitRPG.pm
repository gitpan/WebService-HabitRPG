package WebService::HabitRPG;
use v5.010;
use strict;
use warnings;
use autodie;
use Moo;
use WWW::Mechanize;
use Method::Signatures 20121201;
use JSON::Any;

# ABSTRACT: Perl interface to the HabitRPG API

our $VERSION = '0.14'; # VERSION: Generated by DZP::OurPkg:Version


has 'api_token'  => (is => 'ro'); # aka x-api-key
has 'user_id'    => (is => 'ro'); # aka x-api-user
has 'agent'      => (is => 'rw');
has 'api_base'   => (is => 'ro', default => sub { 'https://habitrpg.com/api/v1' });
has '_last_json' => (is => 'rw'); # For debugging

# use constant URL_BASE => 'https://habitrpg.com/api/v1';

sub BUILD {
    my ($self, $args) = @_;

    # Set a default agent if we don't already have one.

    if (not $self->agent) {
        $self->agent(
            WWW::Mechanize->new(
                agent => "Perl/$], WebService::HabitRPG/" . $self->VERSION,
                keep_alive => 1,
            )
        );
    }

    return;
}


method user()       { return $self->_get_request( '/user'        ); }


method tasks($type where qr{^(?: habit | daily | todo | reward | )$}x = "") {
    if ($type) {
        return $self->_get_request( "/user/tasks?type=$type" ); 
    }
    return $self->_get_request( "/user/tasks" ); 
}


method get_task($task_id) {
    return $self->_get_request("/user/task/$task_id");
}


method new_task(
    :$type! where qr{^(?: habit | daily | todo | reward )$}x,
    :$text!,
    :$completed,
    :$value = 0,
    :$note = '',
    :$up = 1,
    :$down = 1,
    :$extend = {},
) {

    # Magical boolification for JSONification.
    # TODO: These work with JSON::XS. Do they work with other backends?

    $up   = $up   ? \1 : \0;
    $down = $down ? \1 : \0;

    # TODO : The API spec doesn't allow the submission of up/down
    # values, but I feel that *should* be allowed, otherwise
    # creating goals isn't full-featured.

    my $payload = $self->_encode_json({
        type      => $type,
        text      => $text,
        completed => $completed,
        value     => $value,
        note      => $note,
        up        => $up,
        down      => $down,
        %$extend,
    });

    my $req = $self->_build_request('POST', '/user/task');

    $req->content( $payload );

    return $self->_request( $req );

}


method updown(
    $task!,
    $direction! where qr{up|down}
) {

    my $req = $self->_build_request('POST', "/user/tasks/$task/$direction");

    return $self->_request( $req );
}


# Convenience methods
method up  ($task) { return $self->updown($task, 'up'  ); }
method down($task) { return $self->updown($task, 'down'); }


method _update(
    $task!,
    $updates!
) {
    my $payload = $self->_encode_json({
        %$updates,
    });

    my $req = $self->_build_request('PUT', "/user/task/$task");

    $req->content( $payload );

    return $self->_request( $req );
}


# NOTE: We exclude rewards
# NOTE: This returns a list of data structures.
# NOTE: Case insensitive search

method search_tasks($search_term, :$all = 0) {
    my $tasks = $self->tasks;
    my @matches;

    foreach my $task (@$tasks) {

        next if $task->{type} eq 'reward';
        if ($task->{completed} and not $all) { next; }

        # If our search term exactly matches a task ID, then use
        # that.

        if ($task->{id} eq $search_term) {
            return $task;
        }

        if ($task->{text} =~ /\Q$search_term\E/i) {
            push(@matches, $task);
        }
    }
    return @matches;
}

#### Internal use only code beyond this point ####

method _get_request($url) {
    my $req = $self->_build_request('GET', $url);
    return $self->_request( $req );
}

# I don't like the name here, but this makes our request, and decodes
# the JSON-filled result

method _request($req) {
    return $self->_decode_json($self->agent->request( $req )->decoded_content);
}

method _build_request($type, $url) {

    my $req = HTTP::Request->new( $type, $self->api_base . $url );
    $req->header( 'Content-Type'    => 'application/json');
    $req->header( 'x-api-user'      => $self->user_id    );
    $req->header( 'x-api-key'       => $self->api_token  );

    return $req;
}

my $json = JSON::Any->new;

method _decode_json($string) {
    $self->_last_json($string);         # For debugging
    return $json->decode( $string );
}

method _encode_json($string) {
    return $json->encode( $string );
}


1;

__END__

=pod

=head1 NAME

WebService::HabitRPG - Perl interface to the HabitRPG API

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    use WebService::HabitRPG;

    # The API Token and User ID are obained through the
    # Setting -> API link on http://habitrpg.com/

    my $hrpg = WebService::HabitRPG->new(
        api_token => 'your-token-goes-here',
        user_id   => 'your-user-id-goes-here',
    );

    # Get everyting about the user
    my $user = $hrpg->user;

    # Get all tasks.
    my $tasks = $hrpg->tasks;

    # Get all tasks of a particular type (eg: 'daily')
    my $daily = $hrpg->tasks('daily');

    # Increment/decrement a task
    $hrpg->up($task_id);
    $hrpg->down($task_id);

    # Make a new task
    $hrpg->new_task(
        type => 'daily',
        text => 'floss teeth',
        up   => 1,
        down => 0,
    );

=head1 DESCRIPTION

Interface to API provided by L<HabitRPG|http://habitrpg.com/>.

At the time of release, the HabitRPG API is still under construction.
This module may change as a result.

Note that when data structures are returned, they are almost
always straight conversions from the JSON returned by the
HabitRPG API.

=head1 METHODS

=head2 new

    my $hrpg = WebService::HabitRPG->new(
        api_token => 'your-token-goes-here',
        user_id   => 'your-user-id-goes-here',
    );

Creates a new C<WebService::HabitRPG> object. The C<api_token> and C<user_id>
parameters are mandatory. You may also pass your own L<WWW::Mechanize>
compatible user-agent with C<agent>, and should you need it your own HabitRPG
API base URL with C<api_base> (useful for testing, or if you're running your
own server).

By default, the official API base of C<https://habitrpg.com/api/v1> is used.

=head2 user

    my $user = $hrpg->user();

Returns everything from the C</user> route in the HabitRPG API.
This is practically everything about the user, their tasks, scores,
and other information.

The Perl data structure that is returned is a straight conversion
from the JSON provided by the HabitRPG API.

=head2 tasks

    my $tasks  = $hrpg->tasks();            # All tasks
    my $habits = $hrpg->tasks('habit');     # Only habits

Return a reference to an array of tasks. With no arguments, all
tasks (habits, dailies, todos and rewards) are returned. With
an argument, only tasks of the given type are returned. The
argument must be one of C<habit>, C<daily>, C<todo> or C<reward>.

The data returned for each task is defined by the HabitRPG API, but
at the time of writing is:

    {
        text    => 'floss', # Text shown in web interface. Task name.
        type    => 'habit', # One of: habit, todo, daily, reward
        id      => '...',   # Internal task ID. Extensively used by API.
        value   => 0,       # Either cost in GP, or how well one is doing
        notes   => '',      # Extended, human-readable note field
        repeat  => {...},   # Daily tasks only. 
        up      => 1,       # Can this task be incremented?
        down    => 0,       # Can this task be decremented?
        history => [...],   # History data for this task.
    }

Not all tasks will have all fields.  Using the L<hrpg> command-line
tool with C<hrpg dump tasks> is a convenient way to see the
data structures returned by this method.

=head2 get_task

    my $task = $hrpg->get_task('6a11dd4d-c2d6-42b7-b9ff-f562d4ccce4e');

Given a task ID, returns information on that task in the same format
at L</tasks> above.

=head2 new_task

    $hrpg->new_task(
        type      => 'daily',           # Required
        text      => 'floss teeth',     # Required
        up        => 1,                 # Suggested, defaults true
        down      => 0,                 # Suggested, defaults true
        value     => 0,
        note      => "Floss every tooth for great justice",
        completed => 0,
        extend    => {},
    );

Creates a new task. Only the C<type> and C<text> arguments are
required, all other tasks are optional. The C<up> and C<down>
options default to true (ie, tasks can be both incremented and
decremented).

The C<type> parameter must be one of: C<habit>, C<daily>,
C<todo> or C<reward>.

The C<extend> parameter consists to key/value pairs that will be
added to the JSON create packet. This should only be used if you
know what you're doing, and wish to take advantage of new or
undocumented features in the API.

Returns a task data structure of the task created, identical
to the L</tasks> method above.

Creating tasks that can be neither incremented nor decremented
is of dubious usefulness.

=head2 updown

    $hrpg->updown('6a11dd4d-c2d6-42b7-b9ff-f562d4ccce4e', 'up'  );
    $hrpg->updown('6a11dd4d-c2d6-42b7-b9ff-f562d4ccce4e', 'down');

Moves the habit in the direction specified. Returns a data structure
of character status:

    {
        exp   => 11,
        gp    => 15.5,
        hp    => 50,
        lv    => 2,
        delta => 1,
    }

=head2 up

    $hrpg->up($task);

Convenience method. Equivalent to C<$hrpg->updown($task, 'up')>;

=head2 down

    $hrpg->down($task);

Convenience method. Equivalent to C<$hrpg->updown($task, 'down')>;

=head2 _update

    $hrpg->_update($task, { attr => value });

I<This method should be considered experimental.>

Updates the given task on the server (using the underlying C<PUT>
functionality in the API). Attributes are not checked for sanity,
they're just directly converted into JSON.

=head2 search_tasks

    my @tasks = $hrpg->search_tasks($search_term, all => $bool);

    # Eg:
    my @tasks = $hrpg->search_tasks('floss');
    my @tasks = $hrpg->search_tasks('git', all => 1);

Search for tasks which match the provided search term. If the
search term C<exactly> matches a task ID, then the task ID
is returned. Otherwise, returns a list of tasks which contain
the search term in their names (the C<text> field returned by the API).
This list is in the same format as the as the L</tasks> method call.

The search term is treated in a literal, case-insensitive fashion.

If the optional C<all> parameter is set, then all tasks are
returned. Otherwise only non-completed tasks are returned.

This is useful for providing a human-friendly way to refer to
tasks.  For example:

    # Search for a user-provided term
    my @tasks = $hrpg->search_tasks($term);
    
    # Increment task if found
    if (@tasks == 1) {
        $hrpg->up($tasks[0]{id});
    }
    else {
        say "Too few or too many tasks found.";
    }

=for Pod::Coverage BUILD DEMOLISH api_token user_id agent api_base

=head1 BUGS

I'm sure there are plenty! Please view and/or record them at
L<https://github.com/pjf/WebService-HabitRPG/issues> .

=head1 SEE ALSO

The L<HabitRPG API spec|https://github.com/lefnire/habitrpg/wiki/API>.

The L<hrpg> command-line client. It's freakin' awesome.

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
