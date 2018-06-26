#!/srv/wss/util/1.0.6/perl/bin/perl

use lib '/home/techops/New_InstallWrapper/WSS_Install';
use strict;
use warnings;
use Getopt::Long 'HelpMessage';
use Data::Dumper;
use Logger ;
use IO::Socket::INET;
use File::Basename;

GetOptions(

'Directory=s' => \ my $dir,
'Sleep=i' => \ my $sleep,
'help'     =>   sub { HelpMessage(0) },

) or HelpMessage(1) ;

die "$0 requires the directory name  (--Directory)\n" unless $dir;
die "$0 requires the sleep time in secs (--Sleep)\n" unless $sleep;


=head1 NAME 
    
    
=head1 SYNOPSIS
    
--Directory,-D (required)  path to where files needs to be compressed or deleted.
--Sleep, -S (required)  number of seconds before proceeding to next directory under -D specified 
    
=head1 VERSION

0.01

=cut

my $compress_days = 2 ;
my $delete_days = 7 ;

my $date = `date +%Y%m%d.%H`;
chomp($date);
my $Log_Dir = "/tmp";
my $name = basename($0);
my @scriptname = split(/pl/,$name);
Logger::configure(LOG_LEVEL => 'TRACE',
LOG_DIR => "$Log_Dir",
LOG_FILE => "$scriptname[0]$date.log");
my $out ;


##check $dir exists
if ( -e $dir and -d $dir) {
	print "Directory $dir exists! \n";
} else{
	die "Directory $dir doesn't exisits! \n";
}

#my $list_dirs = `ls -1F $dir | /bin/grep "/"`;
my $find_list = `find $dir -name "*"`;
my @result_list = split /\n/,$find_list;
#print Dumper(@result_list);
vlog("List of files found ".Dumper(@result_list)."\n");

foreach my $res (@result_list){
chomp($res);	
	if ((! -d $res) && (($res =~ /\.Z$/) || ($res =~ /\.gz$/) || ($res =~ /\.log$/))){
		my $age = getfileage($res);
			if ( (($res !~ /\.Z$/) && ($res !~ /\.gz$/)) && ( $age > $compress_days ) ){
				print "MARKED for compressing $res : $age OLD \n";
				vlog( "MARKED for compressing $res : $age OLD \n");
				$out = `gzip -9 $res 2>&1 || echo -e 'Cannot compress $res \n'`;
				vlog($out."\n");
		}
                        if ( (($res =~ /\.Z$/) || ($res =~ /\.gz$/) || ($res =~ /\.log$/) ) && ( $age > $delete_days ) ){
                                print "MARKED for deleting $res : $age OLD \n";
                                vlog( "MARKED for deleting $res : $age OLD \n");
				$out = unlink $res || print "Couldn't UNLINK $res \n";
				sleep($sleep);
                }

	}
sleep($sleep);
}

sub getfileage {

	my $file = $_[0];
	my $current_time = time;
	my $file_lastmodifiedtime = (stat $file)[9];
	my $days_difference = int(abs(($file_lastmodifiedtime - $current_time) / 86400));
#	print "$file age is $days_difference days old\n";
	return $days_difference;
}
