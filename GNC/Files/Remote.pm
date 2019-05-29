use strict;

package GSI::DataX::GNC::Files::Remote;

use GSI::DataX::File::Set;

our @ISA = qw(GSI::DataX::File::Set);

use GSI::File::Anywhere::FTP;

use GSI::OptArg::ClassAttr
{
  FILE_TYPE     => { MODIFY   => 1, 
                     DEFAULT  => "binary",
                   }, 
  ACCESS        => { MODIFY   => 1,
                     DEFAULT  => GSI::File::Anywhere::FTP->new
                                 (AUTO_CONNECT => 0, TYPE => 'binary'),
                   },
  CONNECT_OPTS  => { MODIFY   => 1,
# test
#		     DEFAULT  => { HOST          => 'ftp.gsipartners.com',
#				   USER          => 'gncftp',
#				   PASSWORD      => 'g00dhlth',
#				   HEARTBEAT     => 600,
#				 },
# prod
		     DEFAULT  => { HOST          => 'ashprdftp01.gspt.net',
				   USER          => 'gnc',
				   PASSWORD      => 'L!v3We74vr',
				   HEARTBEAT     => 600,
				 },
                   },
  MODE          => { MODIFY   => 1, 
                     DEFAULT  => "READ",
                   }, 
};


package GSI::DataX::GNC::Files::Remote::File;

use GSI::DataX::File::Set;

1;
