# states
california = State.create 'california'
washington = State.create 'washington'

# cities
olympia = City.create 'olympia', washington
seattle = City.create 'seattle', washington

City.create "Los Angeles", california
City.create "Sacramento", california

w = State.find_by_name('washington')

# People
andreas = Person.create 'andreas', olympia
keane = Person.create 'keane', seattle
smith = Person.create 'smith', olympia
arnold = Person.create 'arnold', olympia
peter = Person.create 'peter', seattle

andreas.friends << keane
andreas.save!
keane.friends << smith << arnold
arnold.friends << peter
arnold.save!
keane.save!

# Films
dexter = Film.create 'dexter'

# Likes
keane.likes << dexter
keane.save!

smith.likes << dexter
smith.save!

peter.likes << dexter
peter.save!
