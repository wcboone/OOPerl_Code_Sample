#
# $Id: Content.pm,v 1.1.1.1 2005/10/20 11:08:43 steve Exp $
#

use strict;

package GSI::DataX::GNC::Content;
our $VERSION = 1.00;

use GSI::DataX::GNC::Import;
our @ISA = qw(GSI::DataX::GNC::Import);

use GSI::OptArg::ClassAttr
{
    DATABASE   => { MODIFY         => 1,
                    ALIASES        => [qw/EXISTING_DB MASTER_DB/],
                    DEFAULT        => 'Load',
                  },
    LOAD_DB    => { TYPE           => 'Database', 
                    DEFAULT        => 'Load',
                  },
};

1;
