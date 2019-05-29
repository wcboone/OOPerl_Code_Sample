#
# $Id: Remote.pm,v 1.1 2011/10/31 18:11:38 demij Exp $
#

use strict;

package GSI::DataX::GNC::Catalog::Files::Remote;

use GSI::File::Set::Named;
use GSI::DataX::File::Set;
use GSI::File::Anywhere::FTP;

our @ISA = qw(GSI::File::Set::Named 
              GSI::File::Set
              );

use GSI::OptArg::ClassAttr
{
  NAME            => { MODIFY   => 1,
                     DEFAULT  => "Posted GNC Data Feed File",
                     },
  FILE_TYPE     => { MODIFY   => 1,
                     DEFAULT  => "BINARY",
                   },
  ACCESS        => { MODIFY   => 1,
                     DEFAULT  => GSI::File::Anywhere::FTP->new
                                 (AUTO_CONNECT => 0),
                   },
  CONNECT_OPTS=> { MODIFY     => 1,
                      DEFAULT  => { HOST          => 'f.p.Mybuys.com',
                                    USER          => 'gnc',
                                    PASSWORD      => 'D8zLY4mWR',
 
                                   },
                     },
   PATH       => { MODIFY   => 1,
                   REQUIRED => 0,
                  DEFAULT  => 'GNC_Daily_Category.txt',
                  #DEFAULT  => 'GNC_Daily_Category_test.txt',
                  },
 
  ALWAYS_CD     => { MODIFY   => 1, DEFAULT  =>  1      },
  MODE          => { MODIFY   => 1, DEFAULT  => "WRITE", },

};

package GSI::DataX::GNC::Catalog::Files::Remote::File;

use GSI::File::Set::Named;

our @ISA = qw( GSI::File::Set::Named::File
              GSI::File::Set::File
             );

1;
