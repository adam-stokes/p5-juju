requires "Moose" => "0";
requires "Moose::Autobox" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "IO::Socket::SSL" => "0";
  requires "Mojolicious" => "0";
  requires "Test::Mojo" => "0";
  requires "Test::More" => "0";
  requires "Test::NoTabs" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Test::More" => "0";
  requires "Test::NoTabs" => "0";
};
