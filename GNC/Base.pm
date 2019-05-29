#
# $Id: Base.pm,v 1.3 2005/11/18 15:45:36 donohuet Exp $
#

use strict;

package GSI::DataX::GNC::Base;
our $VERSION = 1.00;

use GSI::DataX::ActionLoader;
our @ISA = qw(GSI::DataX::ActionLoader);

use GSI::OptArg::ClassAttr
{
    DATES    => { TYPE => 'DateRange' },
    DATABASE => { TYPE => 'Database'  },
    DB_NAME  => { TYPE => 'Database'  },
};

1;
