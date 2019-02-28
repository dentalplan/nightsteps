package ns_dbinterface;
{
	use DBI;
	use strict;
	use constant FOUND     => 1;
	use constant NOT_FOUND => 0;
	use open qw/:std :utf8/;

	sub new {
		my $class = shift;
		my $this  = {};
		bless $this, $class;
		return $this;
	}

	sub connectDB {
		my $this = shift;
		my $database = shift;
		my $driver = shift; 
		my $dsn = "DBI:$driver:dbname=$database";
		my $userid = "";
		my $password = "";
		$this->{dbh} = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) 
			      or die $DBI::errstr;
#		return "ERROR: MSQL:\n Did not connect to (SQLITE){DB}: Maybe sqlite is not setup " unless defined $This->{Dbh};
	}

	sub insertValues{
		my ($this, $rh) = @_;
		my $sql =
			"INSERT INTO " . $rh->{table} .
			"( $rh->{fields} )
			VALUES
			( $rh->{values}
			)";
		my $query = $this->{dbh}->prepare($sql);
		my $ex = $query->execute or die $DBI::errstr;
		$query->finish;

		my @key = $this->getPrimaryKeys($rh->{table});
		my $id = $this->{dbh}->last_insert_id(undef,undef, $rh->{table}, $key[0]);
		print "Records created successfully: $id\n";
		return $id;
	}

	sub disconnectDB {
        my $this = shift;
        # connect to database (regular DBI)
        $this->{dbh}->disconnect;
        return;
		print "Disconnected from database\n";
	}

	sub getPrimaryKeys{
		my ($this, $table) = @_;
		my $r_bunch = $this->getTablePragma_rtnBunch($table);
		my $size = @{$r_bunch};
		my $r_arraykeys;
		my $numbkeys = 0;
		for (my $i = 0; $i < $size; $i++){
			if ($r_bunch->[$i]{pk} == 1){
				push (@{$r_arraykeys}, $r_bunch->[$i]{name});
				$numbkeys++;
			}
		}
		if ($numbkeys == 0){
			die "nm_dbinterface::get PrimaryKeys numbkeys==0, no primary key connected";			
		}
		return $r_arraykeys;
	}

	sub getFieldType{
		my ($this, $field, $table) = @_;
		my $r_bunch = $this->getTablePragma_rtnBunch($table);
		my $size = @{$r_bunch};
		my $type;
		my $numbkeys = 0;
		for (my $i = 0; $i < $size; $i++){
			if ($r_bunch->[$i]{name} eq $field){
				$type = $r_bunch->[$i]{type};
			}
		}
		unless (defined $type){
			die "nm_dbinterface::getFieldType no field found";			
		}
		return $type;
	}

	sub getTablePragma_rtnBunch{
		my ($this, $table) = @_;
		my ($r_bunch, @row);
		my @pragma_fields = ('cid', 'name','type','notnull','dfltvalue','pk');
		my $pf_size = @pragma_fields;
		my $query = $this->{dbh}->prepare("PRAGMA table_info($table)");
                $query->execute;
		while (@row = $query->fetchrow_array){
			my $r_fruit;
			for (my $i = 0; $i < $pf_size; $i++){
				my $field = $pragma_fields[$i];
				$r_fruit->{$field} = $row[$i];
			}
			push @{$r_bunch}, $r_fruit;		
		}		
                $query->finish;
		return $r_bunch;
	}

	sub prepValueForSQL{
		my ($this, $rh_value) = @_;
                my $keytype = $this->getFieldType($rh_value->{field}, $rh_value->{table});
                my $keyvalue;
                if ($keytype eq "TEXT"){
                        $keyvalue = "\"" . $rh_value->{value} . "\"";
			print "$keyvalue is $keytype\n";
                }else{	
                        $keyvalue = $rh_value->{value};
		}
		return $keyvalue;
	}

	sub runsql_rtnScalar{
   		 my ($this,	$sql) = @_;
         my $query = $this->{dbh}->prepare($sql);
         $query->execute;	
         my $result = "#FAIL";
         ($result) = $query->fetchrow_array;
         $query->finish;
         print "Returning $result ...\n";
         return $result;
	}

	sub runsql_rtnSuccessOnly{
   		 my (	$this,
			$sql) = @_;
                 my $query = $this->{dbh}->prepare($sql);
                 $query->execute or die $DBI::errstr;
#                 my $result = -1;
                # ($result) = $query->fetchrow_array;
                 $query->finish;
	}

	sub runsql_rtnArrayRef{
                my (    $this,
			 $sql,
                 ) = @_;                 
                my ($r_array, @row);
		my $query = $this->{dbh}->prepare($sql);
                $query->execute;
		while (@row = $query->fetchrow_array){
			push (@{$r_array}, @row);		 
		}		
                $query->finish;
                return $r_array;
	}

	sub runSqlHash_rtnAoHRef{
		my( $this,
		    $r_barrel, 
		) = @_;
		my ($r_bunch, @row);
		my $fields = $this->unpackFields_rtnStr($r_barrel->{fields});
		my $sql = "SELECT " . $fields . 
			  " FROM " . $r_barrel->{table} .
			  $r_barrel->{where} .
			  $r_barrel->{orderby} . ";";
#        print "$sql\n";
		my $query = $this->{dbh}->prepare($sql);
                $query->execute;		
		my $num_fields = @{$r_barrel->{fields}};
		while (@row = $query->fetchrow_array){
			my $r_fruit;
			$r_fruit->{_table} = $r_barrel->{table};
			for (my $i = 0; $i < $num_fields; $i++){
				my $fieldname = $r_barrel->{fields}[$i];
				$r_fruit->{$fieldname} = $row[$i];
			}
			push (@{$r_bunch}, $r_fruit);	
		}
		return $r_bunch;		
	}

	sub runUptBarrel{#make sure you qq the value before sending it here
		my ($this,
		    $r_barrel) = @_;
		my $value = $this->prepValueForSQL($r_barrel);
		my $sql = "UPDATE " . $r_barrel->{table} . 
			" SET " . $r_barrel->{field} . 
			"=" . $value .
			$r_barrel->{where};
		print "$sql\n";
                my $query = $this->{dbh}->prepare($sql);
                $query->execute or die $DBI::errstr;
		$query->finish;
		
	}

	sub unpackFields_rtnStr{
		my ($this,
		    $r_fields
		)= @_;
		my $return= $r_fields->[0];
		my $size = @{$r_fields};
		for (my $i = 1; $i < $size; $i++){
			$return .= ", " . $r_fields->[$i];
		}
		return $return;
	}
}
1;
