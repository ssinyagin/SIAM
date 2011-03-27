=head1 NAME

SIAM::Documentation::DataModel - SIAM data model in details


=head1 INTRODUCTION

Many Service Provider companies (ISP, Hosting, Carriers, ...) have their
own, historically developed, databases for customer service
inventory. Therefore any system that would require access to such data
should be adapted to the local environment.

SIAM is intended as a common API that would connect to
enterprise-specific service inventory systems and present the inventory
data in a uniform format. The purpose of this universal API is to reduce
the integration costs for such software systems as network monitoring,
CRM, Customer self-service portals, etc.

We assume that monitoring systems (such as: Torrus, ...) and front-end
systems (such as: Customer portal, Extopus, ...) would connect to SIAM
to retrieve any service-specific information, and SIAM would deliver a
complete set of data required for those client applications.

SIAM does not include any database of its own: all data is retrieved
directly from the enterprise systems and databases. The SIAM library
communicates with the enterprise-specific back-end drivers and presents
the data in an abstracted way.


SIAM takes its configuration data from a single hierarchical data
structure. This data is usually read from a YAML file.  The
configuration describes all data connections, driver configuration,
enterprise-specific modules, etc.

The SIAM core modules are distributed as an open-source Perl package
available at CPAN. Enterprise-specific modules are integrated in a way
that the core can be upgraded without breaking any local setup.


=head1 DATA MODEL

=head2 Conventions

Each object is defined by a set of attributes. Some attributes are mandatory
for a particular object class. 

Visibility of attributes and their values is defined by Access Scope
associated with a particular client user.

Further in this document, a pair of square brackets ([]) in attribute
name identifies that its value is an array of strings.

Attribute names with certain prefixes are reserved solely for SIAM use:
object.*, contract.*, svc.*, svcunit.*, svcdata.*, ...

In boolean attributes, numerical zero is interpreted as "false", and numerical
nonzero is treated as "true". Usually numerical 1 indicates a true value.

Some attributes contain identifiers of other objects. The string value I<NIL>
is reserved to indicate an undefined identifier.


In this document, XYZ refers to the enterprise name.

=head2 SIAM::Object

All SIAM object classes (including the root-level C<SIAM> class) are
derived from C<SIAM::Object> class. The following attributes are
mandatory for every object:

=over 4

=item * object.id

The attribute defines a unique identifier for the object. Client
applications must not set any assumptions on the ID values or their
structure. The back-end drivers generate the ID values, and these values
are only meaningful within the driver data model.  Maximum length: 1024
bytes.


=item * object.class

The full Perl package name of the object, such as I<SIAM::ServiceUnit>.
The back-end drivers should rely on these values in their internal
logics.  The drivers should be flexible enough to accept new object
classes without breaking the logics.

=item * object.container_id

Each object (except for the root) is contained in another object, and
may also be a container for other objects. This attribute defines the ID
of the container object. The root object has this attribute set to C<NIL>, and
it is the most reliable way to identify the root object.

=back




=head2 SIAM::Contract

The enterprise billing system would usually work with
contracts. Contracts consist of services.

Mandatory attributes:

=over 4

=item * contract.inventory_id

Contract identifier in external inventory. This should refer to the
contract number as seen in the enterprise billing system.

=item * contract.customer_name

String identifying the contract holder name

=item * contract.access_scope_id[]

Access Scopes associated with this contract. They control visibility of
the data to various users.

=item * contract.last_modified

UNIX timestamp of last change in any contract details. This attribute
may be set to zero if the underlying system is unable to deliver the last
modification time.

=back


Attribute examples:

=over 4

=item * xyz.is_suspended, xyz.billing_ok, xyz.reseller_id

These define the internal logic which is specific to particular SIAM use.

=back



=head2 SIAM::Service

A Service is a billing unit within the enterprise. It consists of Service
Units.


Mandatory attributes:

=over 4

=item * svc.name

Service name as displayed to the user.

=item * svc.type

A string from a limited dictionary of predefined service types. It
refers to a service template which identifies the attributes which are
required for each service type.

=item * svc.inventory_id

Service ID in external inventory, such as the billing system.

=back



=head2 SIAM::ServiceUnit

Service Unit is an elementary physical entity comprising a Service. For
example, a WAN connection may consist of several physical links, and
each link would be identified as a Unit.

In many SP environments each Service would only consist of one
Unit. This assignment depends on the internal SP service definitions.

A ServiceUnit consists of Service Options, such as access speed, hosting
disk size, etc, and Implementation Attributes, such as link identifier,
access port, rack number, etc.

Service Options are usually visible to the customer and are defined in
their contract.

Implementation Attributes are internal Service Provider's properties
that document the technical details of the installation.

Mandatory attributes:

=over 4

=item * svcunit.name

Service Unit name as displayed to the user.

=item * svcunit.type

A string from a limited dictionary of predefined service unit types. It
refers to a service template which identifies the attributes which are
required for each unit type.

=item * svcunit.inventory_id

Service Unit ID in external inventory. If it's a strict one-to-one relation
between Services and their Units, this attribute is equal to
C<svc.inventory_id>.

=back


Attribute examples:

=over 4

=item * access.speed.downstream, vm.ram.size

Examples of Service Options.

=item * access.node.name, access.port.name, rack.number

Examples of Implementation Attributes.

=back




=head2 SIAM::ServiceDataElement

Service Units define the physical entities, whereas Data Elements refer
to associated data, such as statistics.

Each instance of a Service Unit is usually associated with several data
elements. For example, a physical link is associated with TrafficStats,
ErrorStats, MonthlyUsage.

Each Data Element represents a connection to some back-end system that
actually delivers the data. SIAM provides all attributes necessary for
accessing the data. It is up to the client application to retrieve the
data from the back-end system.

Mandatory attributes:

=over 4

=item * svcdata.name

Data Element name as displayed to the user. SIAM clients should only use
it for displaying, and should not build any logic on its value.

=item * svcdata.type

A string from a limited dictionary. SIAM clients may build the data
representation based on the value of this attribute. Example:
“TrafficStats”.

=item * svcdata.driver_class

Name of the data driver. 
Examples: I<Torrus::SIAM::TimeSeries>, I<Torrus::SIAM::MonthlyUsage>

=item * svcdata.available

If the data driver is not ready to provide the data, this
attribute must return false value. The front-end system should inform
the user that the data is currently unavailable if this attribute
returns a false value.

=back


Attribute examples:

=over 4

=item * torrus.server, torrus.tree, torrus.nodeid

Example of a reference to a Torrus data element.

=item * monthly_usage.dsn, monthly_usage.username, monthly_usage.password,
monthly_usage.svcid

Example of a reference to Torrus monthly traffic statistics, such as
95th Percentile bandwidth utilization.


=item * vmstats.dsn, vmstats.username, vmstats.password, vmstats.vm_server,
vmstats.vm_entity, ...

Example of a reference to VmWare server statistics in an SQL database.

=back



=head2 SIAM::AccessScope

Access Scope determines the subset of contracts and other objects that
are visible to particular users.  The default security model provides
the means for limiting access to Contracts and individual attribute
names.

Two scope names are reserved, and corresponding objects always belong to
them: I<AllContracts>, I<AllAttributes>.

Access Scope objects are contained within the root SIAM object.

Mandatory attributes:

=over 4

=item * scope.name

Unique name of Access Scope. It has usually a mnemonic value, such as
I<AllContracts>, I<Contract#123456>, I<Wholesale#654321>.

=item * scope.applies_to

Class of objects that this scope covers. Known values: I<SIAM::Contract>,
I<SIAM::Attribute>.

=back



=head2 SIAM::User

User is usually associated with a physical person that accesses the
system. SIAM is not responsible for authenticating the users, although
it may carry the information required for authentication.

User objects may contain any of the RFC4519 (LDAP User Schema)
attributes. It depends on the local interpretation which of them are
available, and also the meaning of these attributes.

User objects are contained within the root C<SIAM> object.

Mandatory attributes:

=over 4

=item * user.uid

Unique user ID that is known through some authentication mechanism.

=back


Attribute examples:

=over 4

=item * user.cn

Common Name attribute in an LDAP database.

=back




=head2 SIAM::Privilege

Privilege is a binding object between Users and Access Scopes. The
relation between users and their privileges is maintained by
enterprise-specific SIAM drivers, and may be based, for example, on LDAP
group membership.

Privilege objects are contained in C<SIAM::User> objects.

Mandatory attributes:

=over 4

=item * privilege.scope_id

Reference to the corresponding C<SIAM::AccessScope> object ID.

=item * privilege.type

String from a limited dictionary of known privilege types. Examples:
I<ViewContract>, I<ViewAttribute>, I<SuspendContract>

=back



=head2 SIAM::Attribute

Attribute objects are only used for their relation to Access
Scopes. This relation is usually static and stored directly in SIAM
configuration.

For example, some Implementation Attributes, such as I<access.node.name>,
I<access.port.name>, I<rack.number>, would be associated with the scope
I<ImplementarionAttributes>, and only the ISP personnel users would be
able to see their values.

C<SIAM::Attribute> objects are contained within C<SIAM::AccessScope> objects.

Mandatory attributes:

=over 4

=item * attribute.name

Name of the attribute.

=back






=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stanislav Sinyagin.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut
