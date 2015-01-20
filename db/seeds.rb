# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Country.where(name: 'Estonia', iso: 'EE').first_or_create!
Country.where(name: 'Latvia', iso: 'LV').first_or_create!

registrar1 = Registrar.where(
  name: 'Registrar First AS',
  reg_no: '10300220',
  address: 'Pärnu mnt 2, Tallinna linn, Harju maakond, 11415',
  country: Country.first
).first_or_create

EppUser.where(
  username: 'registrar1',
  password: 'test1',
  active: true,
  registrar: registrar1
).first_or_create

registrar2 = Registrar.where(
  name: 'Registrar Second AS',
  reg_no: '10529229',
  address: 'Vabaduse pst 32, 11316 Tallinn',
  country: Country.first
).first_or_create

EppUser.where(
  username: 'registrar2',
  password: 'test2',
  active: true,
  registrar: registrar2
).first_or_create

User.where(
  username: 'user1',
  password: 'test1',
  email: 'user1@example.ee',
  identity_code: '37810013855',
  country: Country.where(name: 'Estonia').first
).first_or_create

User.where(
  username: 'user2',
  password: 'test2',
  email: 'user2@example.ee',
  identity_code: '37810010085',
  country: Country.where(name: 'Estonia').first
).first_or_create

User.where(
  username: 'user3',
  password: 'test3',
  email: 'user3@example.ee',
  identity_code: '37810010727',
  country: Country.where(name: 'Estonia').first
).first_or_create

User.update_all(roles: ['admin'])
# Setting.whois_enabled = true only uncomment this if you wish whois
