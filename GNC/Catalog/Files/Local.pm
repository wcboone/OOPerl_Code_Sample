#
# $Id: Local.pm,v 1.1 2011/10/31 18:11:38 demij Exp $
#

use strict;

package GSI::DataX::GNC::Catalog::Files::Local;

use GSI::File::Set::StandardDated;
use GSI::DataX::File::Set;

our @ISA = qw(GSI::File::Set::StandardDated GSI::DataX::File::Set);

use GSI::OptArg::ClassAttr
{
  NAME         => { MODIFY   => 1, 
                    DEFAULT  => "Local GNC Data Feed Files",
                  }, 
  FILE_TYPE    => { MODIFY   => 1, 
                    DEFAULT  => "ASCII",
                  }, 
  MODE         => { MODIFY   => 1, 
                    DEFAULT  => "WRITE",
                  }, 
  TEMPLATE     => { MODIFY   => 1, 
                    REQUIRED => 0,
                    DEFAULT  => "{X_DATA_ROOT}/local/YYYYMMDD.txt",
                  },
  CLEAN_POLICY => { MODIFY   => 1,
                    DEFAULT  => '11 days ago',
                  },
};

package GSI::DataX::GNC::Catalog::Files::Local::File;

use GSI::File::Set::StandardDated;

our @ISA = qw(GSI::File::Set::StandardDated::File);

1;
