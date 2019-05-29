#=============================================================
# COPYRIGHT (c) 2007 GSI Commerce Inc
# All rights are reserved. Reproduction in whole or in part 
# is prohibited without the written consent of the copyright 
# owner.                                                      
#-------------------------------------------------------------
#
#System :    Perl 
#Department: IST/Business Integration/Feeds
#Package :   GSI::DataX::GNC
#File    :   Export.pm
#Author  :   
#Desc    :    
#Date      Auth    Ref/Description
#--------- ------- ------------------------------------------
#5/3/2007  ArnottS Added/Modified db aliases for new 10g production server...
#5/3/2007  ArnottS Added new copyright header... :)
#
# $Id: Catalog.pm,v 1.2 2011/11/07 17:29:27 demij Exp $
#

use strict;

package GSI::DataX::GNC::Catalog;
our $VERSION = 1.00;

use GSI::DataX::GNC::Base;
our @ISA = qw(GSI::DataX::GNC::Base);

use GSI::OptArg::ClassAttr {
    DB_NAME     => { MODIFY      => 1, 
                     DEFAULT    => 'AMAFDAAP',  # 'Catman' for production
                   },

};

sub post_check_opts
{
    my $self = shift;
    my $opts = shift;

    $self->_default_flags(qw/LOCAL REMOTE/);

    $self->_default_action(qw/Create Upload/);

    return 1;
}

1;
