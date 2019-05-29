#
# $Id: Remote.pm,v 1.2 2012/09/11 13:49:30 lagishettys Exp $
#

use strict;

package GSI::DataX::GNC::Report::MissingImage::Files::Remote;

our $VERSION = 1.00;

use GSI::File::Set::Named;
use GSI::DataX::File::Set;
our @ISA = qw(GSI::File::Set::Named GSI::DataX::File::Set);

use GSI::File::Anywhere::FTP;

use GSI::OptArg::ClassAttr
{
  NAME          => { MODIFY   => 1,
                     DEFAULT  => "GNC ",
                   },
  PATH          => { MODIFY   => 1,
                     REQUIRED => 0,
                     DEFAULT  => 'GNCLabelImages/GNCLabelImages.txt',
                   },
  FILE_TYPE     => { MODIFY   => 1,
                     DEFAULT  => "ASCII",
                   },
  ACCESS        => { MODIFY   => 1,
                     DEFAULT  => GSI::File::Anywhere::FTP->new
                                 (AUTO_CONNECT => 0),
                   },
  CONNECT_OPTS  => { MODIFY   => 1,
                     DEFAULT  => { HOST     => 'ftp.gsipartners.com',
                                   USER     => 'gncftp',
                                   PASSWORD => 'g00dhlth',
                                 },
                   },

#  TEMPLATE       => { MODIFY   => 1,
#                      REQUIRED => 0,
#                      DEFAULT  => 'GNCLabelImages/GNCLabelImages.txt',
#                    },
  MODE          => { MODIFY   => 1,
                     DEFAULT  => "READ",
                   },
};

package GSI::DataX::GNC::Report::MissingImage::Files::Remote::File;

use GSI::File::Set::Named;
use GSI::DataX::File::Set;

our @ISA = qw(GSI::File::Set::Named::File GSI::DataX::File::Set::File);


1;

