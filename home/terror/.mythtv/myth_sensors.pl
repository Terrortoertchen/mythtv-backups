#!/usr/bin/perl -w
# myth_sensors.pl
#
# Retrieves sensors output and formats it for inclusion in the MythTV backend
# status page.
#
# You may specify the sensors_command_line as well as the data to retrieve and
# the output information as described in the comments, below.


# Change the command line required to execute the sensors program, below.
# The default value should work as long as sensors is in the PATH for the user
# running mythbackend
    my $sensors_command_line = '/usr/bin/sensors';

# Specify the data to retrieve and the output information in the format:
#
# [ "<sensors label>", "<display output>", "<XML output name>" ]
#
# where <sensors label> is the label used by the sensors program for the
# value you wish to include and <display output> may contain "%v" at the
# location where the value should be placed.  If <display output> does not
# contain "%v", the value will be appended to the end.  The <XML output name>
# is an optional value for the "name" attribute, which can be used to make
# machine parsing easier.
    my @output = (
                  [ "temp1", "Current CPU Temperature: %v", "temperature-CPU" ],
                  [ "fan2", "Current CPU Fan Speed: %v", "fan-CPU" ],
                  [ "temp3", "Current Motherboard Temperature: %v", "temperature-MB" ],
                  [ "chassis", "Current Case Fan Speed: %v", "fan-case" ],
    );

# Editing the following code should not be necessary.
    my $line = 0;
    my %data = ();
    my ($label, $display, $value, $name);

    my @sensors_data = `$sensors_command_line`;

    while ($sensors_data[$line])
    {
        $sensors_data[$line] =~ /^(.+):\s+(?:\+|-)?(\d+\.?\d*)/;
        if ($1 && $2)
        {
            $data{ $1 } = $2;
        }
        $line++;
    }
    for $i (0 .. $#output) {
        $label = $output[$i][0];
        $value = $data{$label};
        if ($value)
        {
            $display = $output[$i][1];
            $name = $output[$i][2];
            $display = "$display %v" unless ($display =~ /%v/);
            $display =~ s/%v/$value/;
            print("${display}");
            print("[]:[]${name}") if ($name);
            print("[]:[]${value}") if ($name && $value);
            print("\n");
        }
    }

