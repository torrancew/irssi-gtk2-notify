use strict;
use vars qw( $VERSION %IRSSI %settings $notification $last_notification_time );

use Irssi;
use Gtk2::Notify qw( -init irssi );
use Time::HiRes  qw( gettimeofday tv_interval);

$VERSION = '0.90';
%IRSSI   = (
  authors     => 'Tray Torrance',
  contact     => 'devwork@warrentorrance.com',
  name        => 'Notify',
  description => 'This script notifies a user via libnotify upon highlights.',
  license     => 'GNU GPL, version 3.0',
);

%settings = (
  icon  => 'gtk-dialog-info',
  time  => 1.0,
  delay => 1.5,
);

# Helper method to redefine time() and use gettimeofday from Time::HiRes
sub time {
  return [ gettimeofday() ];
}

# Helper method for enforcing a notification delay
sub delay {
  return tv_interval( $last_notification_time ) > $settings{delay};
}

# A general warpper for invoking libnotify.
# Uses a global $notification object, and
# silently attempts to close it before each use.
sub notify {
  my ( $summary, $message ) = @_;
  my $timeout = $settings{time} * 1000;

  eval { $notification->close() };
  $notification = Gtk2::Notify->new( $summary, $message, $settings{icon} );
  $notification->set_timeout( $timeout );
  $notification->show();
}

# Notify on private messages
sub notify_pm {
  my ( $server, $msg, $nick, $address ) = @_;

  return unless $server;
  return unless delay();

  notify( $nick, $msg );
  $last_notification_time = &time;
}

# Filter and notify if the current nick is mentioned in public chat
sub notify_mention {
  my ( $server, $msg, $nick, $address, $target ) = @_;

  return unless $server;
  return if $nick eq $server->{nick};
  return unless $msg =~ /$server->{nick}/;
  return unless tv_interval( $last_notification_time ) > $settings{delay};

  $msg =~ s/^$server->{nick}://;
  notify( "$target/$nick", $msg );
  $last_notification_time = &time;
}

# Set the time initially
$last_notification_time = &time;

Irssi::signal_add( 'message public',  'notify_mention' );
Irssi::signal_add( 'message private', 'notify_pm' );

