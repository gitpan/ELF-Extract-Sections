package ELF::Extract::Sections::Scanner::Objdump;
our $VERSION = '0.0104';


# ABSTRACT: An C<objdump> based section scanner.

# $Id:$
use strict;
use warnings;
use MooseX::Declare;

class ELF::Extract::Sections::Scanner::Objdump
with ELF::Extract::Sections::Meta::Scanner {
    use MooseX::Has::Sugar 0.0300;
    use MooseX::Types::Moose ( 'Bool', 'HashRef', 'RegexpRef', 'FileHandle', );
    use MooseX::Types::Path::Class ('File');

    has _header_regex => ( isa => RegexpRef, ro, default => sub { return qr/<(?<header>[^>]+)>/; }, );
    has _offset_regex => ( isa => RegexpRef, ro, default => sub { return qr/\(File Offset:\s*(?<offset>0x[0-9a-f]+)\)/; }, );
    has _section_header_identifier => ( isa => RegexpRef,  ro, lazy_build, );
    has _file                      => ( isa => File,       rw, clearer => '_clear_file', );
    has _filehandle                => ( isa => FileHandle, rw, clearer => '_clear_filehandle', );
    has _state                     => ( isa => HashRef,    rw, predicate => '_has_state', clearer => '_clear_state', );

    #
    # Interface Methods
    #
    method open_file ( File :$file! ){
        $self->log->debug("Opening $file");
        $self->_file($file);
        $self->_filehandle( $self->_objdump );
        return 1;
    };

    method next_section {
        my $re = $self->_section_header_identifier;
        my $fh = $self->_filehandle;
        while ( my $line = <$fh> ) {
            next if $line !~ $re;
            my ( $header, $offset ) = ( $+{header}, $+{offset} );
            $self->_state( { header => $header, offset => $offset } );
            $self->log->info("objdump -D -F : Section $header at $offset");

            return 1;
        }
        $self->_clear_file;
        $self->_clear_filehandle;
        $self->_clear_state;
        return 0;
    };

    method section_offset {
        if ( not $self->_has_state ) {
            $self->log->logcroak('Invalid call to section_offset outside of file scan');
            return;
        }
        return hex( $self->_state->{offset} );
    };

    method section_size {
        $self->log->logcroak('Can\'t perform section_size on this type of object.');
    };

    method section_name {
        if ( not $self->_has_state ) {
            $self->log->logcroak('Invalid call to section_name outside of file scan');
        }
        return $self->_state->{header};
    };

    method can_compute_size {
        return 0;
    };

    #
    # Internals
    #

    method _build__section_header_identifier {
        my $header = $self->_header_regex;
        my $offset = $self->_offset_regex;

        return qr/${header}\s*${offset}:/;
    };

    method _objdump {
        if ( open my $fh, '-|', 'objdump', qw( -D -F ), $self->_file->cleanup->absolute ) {
            return $fh;
        }
        $self->log->logconfess(qq{An error occured requesting section data from objdump $^ $@ });
        return;
    };

};
1;




=pod

=head1 NAME

ELF::Extract::Sections::Scanner::Objdump - An C<objdump> based section scanner.

=head1 VERSION

version 0.0104

=head1 Description

This module is a model implementaiton of a Naive and system relaint ELF Section detector.
Its currently highly inefficient due to having to run the entire ELF through a disassembly
process to determine the section positions and only I<guesses> at section lengths by
advertisng that it cant' compute sizes.

=head1 Does

This module is a Performer of L<ELF::Extract::Sections::Meta::Scanner>

=head1 Methods

See  L<ELF::Extract::Sections::Meta::Scanner> for a method breakdown.

=head1 Synopsis

TO use this module, simply initialise L<ELF::Extract::Sections> as so

    my $extractor  = ELF::Extract::Sections->new(
            file => "/path/to/file.so" ,
            scanner => "Objdump",
    );

=head1 AUTHOR

  Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__END__

