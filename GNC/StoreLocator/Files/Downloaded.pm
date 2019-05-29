
use strict;

package GSI::DataX::GNC::StoreLocator::Files::Downloaded;

use GSI::File::Set::StandardDated;
use GSI::DataX::File::Set;

our @ISA = qw(GSI::File::Set::StandardDated
              GSI::DataX::File::Set);

use GSI::OptArg::ClassAttr
{
  NAME         => { MODIFY   => 1,
                    DEFAULT  => "Downloaded GNC StoreLocator Files",
                  },
  FILE_TYPE    => { MODIFY   => 1,
                    DEFAULT  => "ASCII",
                  },
  MODE         => { MODIFY   => 1,
                    DEFAULT  => "READ",
                  },
  TEMPLATE     => { MODIFY   => 1,
                    REQUIRED => 0,
                    DEFAULT  => '{X_DATA_ROOT}/downloaded/YYYYMMDDHHMMSS.txt',
                    #DEFAULT  => '{X_DATA_ROOT}/downloaded/YYYYMMDDHHMMSS.xls',
                  },
};

package GSI::DataX::GNC::StoreLocator::Files::Downloaded::File;

use GSI::File::Set::StandardDated;
use GSI::DataX::File::Set;

our @ISA = qw(GSI::File::Set::StandardDated::File
              GSI::DataX::File::Set);

1;
