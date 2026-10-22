// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _companyMeta =
      const VerificationMeta('company');
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
      'company', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _departmentMeta =
      const VerificationMeta('department');
  @override
  late final GeneratedColumn<String> department = GeneratedColumn<String>(
      'department', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _phoneMobileMeta =
      const VerificationMeta('phoneMobile');
  @override
  late final GeneratedColumn<String> phoneMobile = GeneratedColumn<String>(
      'phone_mobile', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _phoneOfficeMeta =
      const VerificationMeta('phoneOffice');
  @override
  late final GeneratedColumn<String> phoneOffice = GeneratedColumn<String>(
      'phone_office', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _faxMeta = const VerificationMeta('fax');
  @override
  late final GeneratedColumn<String> fax = GeneratedColumn<String>(
      'fax', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _websiteMeta =
      const VerificationMeta('website');
  @override
  late final GeneratedColumn<String> website = GeneratedColumn<String>(
      'website', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
      'memo', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _imageFrontMeta =
      const VerificationMeta('imageFront');
  @override
  late final GeneratedColumn<String> imageFront = GeneratedColumn<String>(
      'image_front', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageBackMeta =
      const VerificationMeta('imageBack');
  @override
  late final GeneratedColumn<String> imageBack = GeneratedColumn<String>(
      'image_back', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbMeta = const VerificationMeta('thumb');
  @override
  late final GeneratedColumn<String> thumb = GeneratedColumn<String>(
      'thumb', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ocrRawMeta = const VerificationMeta('ocrRaw');
  @override
  late final GeneratedColumn<String> ocrRaw = GeneratedColumn<String>(
      'ocr_raw', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _lowConfidenceMeta =
      const VerificationMeta('lowConfidence');
  @override
  late final GeneratedColumn<String> lowConfidence = GeneratedColumn<String>(
      'low_confidence', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        company,
        department,
        title,
        phoneMobile,
        phoneOffice,
        fax,
        email,
        address,
        website,
        memo,
        imageFront,
        imageBack,
        thumb,
        ocrRaw,
        source,
        lowConfidence,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(Insertable<Contact> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('company')) {
      context.handle(_companyMeta,
          company.isAcceptableOrUnknown(data['company']!, _companyMeta));
    }
    if (data.containsKey('department')) {
      context.handle(
          _departmentMeta,
          department.isAcceptableOrUnknown(
              data['department']!, _departmentMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('phone_mobile')) {
      context.handle(
          _phoneMobileMeta,
          phoneMobile.isAcceptableOrUnknown(
              data['phone_mobile']!, _phoneMobileMeta));
    }
    if (data.containsKey('phone_office')) {
      context.handle(
          _phoneOfficeMeta,
          phoneOffice.isAcceptableOrUnknown(
              data['phone_office']!, _phoneOfficeMeta));
    }
    if (data.containsKey('fax')) {
      context.handle(
          _faxMeta, fax.isAcceptableOrUnknown(data['fax']!, _faxMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('website')) {
      context.handle(_websiteMeta,
          website.isAcceptableOrUnknown(data['website']!, _websiteMeta));
    }
    if (data.containsKey('memo')) {
      context.handle(
          _memoMeta, memo.isAcceptableOrUnknown(data['memo']!, _memoMeta));
    }
    if (data.containsKey('image_front')) {
      context.handle(
          _imageFrontMeta,
          imageFront.isAcceptableOrUnknown(
              data['image_front']!, _imageFrontMeta));
    }
    if (data.containsKey('image_back')) {
      context.handle(_imageBackMeta,
          imageBack.isAcceptableOrUnknown(data['image_back']!, _imageBackMeta));
    }
    if (data.containsKey('thumb')) {
      context.handle(
          _thumbMeta, thumb.isAcceptableOrUnknown(data['thumb']!, _thumbMeta));
    }
    if (data.containsKey('ocr_raw')) {
      context.handle(_ocrRawMeta,
          ocrRaw.isAcceptableOrUnknown(data['ocr_raw']!, _ocrRawMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('low_confidence')) {
      context.handle(
          _lowConfidenceMeta,
          lowConfidence.isAcceptableOrUnknown(
              data['low_confidence']!, _lowConfidenceMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      company: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company'])!,
      department: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}department'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      phoneMobile: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_mobile'])!,
      phoneOffice: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_office'])!,
      fax: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fax'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      website: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}website'])!,
      memo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo'])!,
      imageFront: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_front']),
      imageBack: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_back']),
      thumb: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumb']),
      ocrRaw: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ocr_raw'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      lowConfidence: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}low_confidence'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final String id;
  final String name;
  final String company;
  final String department;
  final String title;
  final String phoneMobile;
  final String phoneOffice;
  final String fax;
  final String email;
  final String address;
  final String website;
  final String memo;
  final String? imageFront;
  final String? imageBack;
  final String? thumb;
  final String ocrRaw;
  final String source;
  final String lowConfidence;
  final int createdAt;
  final int updatedAt;
  const Contact(
      {required this.id,
      required this.name,
      required this.company,
      required this.department,
      required this.title,
      required this.phoneMobile,
      required this.phoneOffice,
      required this.fax,
      required this.email,
      required this.address,
      required this.website,
      required this.memo,
      this.imageFront,
      this.imageBack,
      this.thumb,
      required this.ocrRaw,
      required this.source,
      required this.lowConfidence,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['company'] = Variable<String>(company);
    map['department'] = Variable<String>(department);
    map['title'] = Variable<String>(title);
    map['phone_mobile'] = Variable<String>(phoneMobile);
    map['phone_office'] = Variable<String>(phoneOffice);
    map['fax'] = Variable<String>(fax);
    map['email'] = Variable<String>(email);
    map['address'] = Variable<String>(address);
    map['website'] = Variable<String>(website);
    map['memo'] = Variable<String>(memo);
    if (!nullToAbsent || imageFront != null) {
      map['image_front'] = Variable<String>(imageFront);
    }
    if (!nullToAbsent || imageBack != null) {
      map['image_back'] = Variable<String>(imageBack);
    }
    if (!nullToAbsent || thumb != null) {
      map['thumb'] = Variable<String>(thumb);
    }
    map['ocr_raw'] = Variable<String>(ocrRaw);
    map['source'] = Variable<String>(source);
    map['low_confidence'] = Variable<String>(lowConfidence);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      name: Value(name),
      company: Value(company),
      department: Value(department),
      title: Value(title),
      phoneMobile: Value(phoneMobile),
      phoneOffice: Value(phoneOffice),
      fax: Value(fax),
      email: Value(email),
      address: Value(address),
      website: Value(website),
      memo: Value(memo),
      imageFront: imageFront == null && nullToAbsent
          ? const Value.absent()
          : Value(imageFront),
      imageBack: imageBack == null && nullToAbsent
          ? const Value.absent()
          : Value(imageBack),
      thumb:
          thumb == null && nullToAbsent ? const Value.absent() : Value(thumb),
      ocrRaw: Value(ocrRaw),
      source: Value(source),
      lowConfidence: Value(lowConfidence),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Contact.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      company: serializer.fromJson<String>(json['company']),
      department: serializer.fromJson<String>(json['department']),
      title: serializer.fromJson<String>(json['title']),
      phoneMobile: serializer.fromJson<String>(json['phoneMobile']),
      phoneOffice: serializer.fromJson<String>(json['phoneOffice']),
      fax: serializer.fromJson<String>(json['fax']),
      email: serializer.fromJson<String>(json['email']),
      address: serializer.fromJson<String>(json['address']),
      website: serializer.fromJson<String>(json['website']),
      memo: serializer.fromJson<String>(json['memo']),
      imageFront: serializer.fromJson<String?>(json['imageFront']),
      imageBack: serializer.fromJson<String?>(json['imageBack']),
      thumb: serializer.fromJson<String?>(json['thumb']),
      ocrRaw: serializer.fromJson<String>(json['ocrRaw']),
      source: serializer.fromJson<String>(json['source']),
      lowConfidence: serializer.fromJson<String>(json['lowConfidence']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'company': serializer.toJson<String>(company),
      'department': serializer.toJson<String>(department),
      'title': serializer.toJson<String>(title),
      'phoneMobile': serializer.toJson<String>(phoneMobile),
      'phoneOffice': serializer.toJson<String>(phoneOffice),
      'fax': serializer.toJson<String>(fax),
      'email': serializer.toJson<String>(email),
      'address': serializer.toJson<String>(address),
      'website': serializer.toJson<String>(website),
      'memo': serializer.toJson<String>(memo),
      'imageFront': serializer.toJson<String?>(imageFront),
      'imageBack': serializer.toJson<String?>(imageBack),
      'thumb': serializer.toJson<String?>(thumb),
      'ocrRaw': serializer.toJson<String>(ocrRaw),
      'source': serializer.toJson<String>(source),
      'lowConfidence': serializer.toJson<String>(lowConfidence),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Contact copyWith(
          {String? id,
          String? name,
          String? company,
          String? department,
          String? title,
          String? phoneMobile,
          String? phoneOffice,
          String? fax,
          String? email,
          String? address,
          String? website,
          String? memo,
          Value<String?> imageFront = const Value.absent(),
          Value<String?> imageBack = const Value.absent(),
          Value<String?> thumb = const Value.absent(),
          String? ocrRaw,
          String? source,
          String? lowConfidence,
          int? createdAt,
          int? updatedAt}) =>
      Contact(
        id: id ?? this.id,
        name: name ?? this.name,
        company: company ?? this.company,
        department: department ?? this.department,
        title: title ?? this.title,
        phoneMobile: phoneMobile ?? this.phoneMobile,
        phoneOffice: phoneOffice ?? this.phoneOffice,
        fax: fax ?? this.fax,
        email: email ?? this.email,
        address: address ?? this.address,
        website: website ?? this.website,
        memo: memo ?? this.memo,
        imageFront: imageFront.present ? imageFront.value : this.imageFront,
        imageBack: imageBack.present ? imageBack.value : this.imageBack,
        thumb: thumb.present ? thumb.value : this.thumb,
        ocrRaw: ocrRaw ?? this.ocrRaw,
        source: source ?? this.source,
        lowConfidence: lowConfidence ?? this.lowConfidence,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      company: data.company.present ? data.company.value : this.company,
      department:
          data.department.present ? data.department.value : this.department,
      title: data.title.present ? data.title.value : this.title,
      phoneMobile:
          data.phoneMobile.present ? data.phoneMobile.value : this.phoneMobile,
      phoneOffice:
          data.phoneOffice.present ? data.phoneOffice.value : this.phoneOffice,
      fax: data.fax.present ? data.fax.value : this.fax,
      email: data.email.present ? data.email.value : this.email,
      address: data.address.present ? data.address.value : this.address,
      website: data.website.present ? data.website.value : this.website,
      memo: data.memo.present ? data.memo.value : this.memo,
      imageFront:
          data.imageFront.present ? data.imageFront.value : this.imageFront,
      imageBack: data.imageBack.present ? data.imageBack.value : this.imageBack,
      thumb: data.thumb.present ? data.thumb.value : this.thumb,
      ocrRaw: data.ocrRaw.present ? data.ocrRaw.value : this.ocrRaw,
      source: data.source.present ? data.source.value : this.source,
      lowConfidence: data.lowConfidence.present
          ? data.lowConfidence.value
          : this.lowConfidence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('company: $company, ')
          ..write('department: $department, ')
          ..write('title: $title, ')
          ..write('phoneMobile: $phoneMobile, ')
          ..write('phoneOffice: $phoneOffice, ')
          ..write('fax: $fax, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('website: $website, ')
          ..write('memo: $memo, ')
          ..write('imageFront: $imageFront, ')
          ..write('imageBack: $imageBack, ')
          ..write('thumb: $thumb, ')
          ..write('ocrRaw: $ocrRaw, ')
          ..write('source: $source, ')
          ..write('lowConfidence: $lowConfidence, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      company,
      department,
      title,
      phoneMobile,
      phoneOffice,
      fax,
      email,
      address,
      website,
      memo,
      imageFront,
      imageBack,
      thumb,
      ocrRaw,
      source,
      lowConfidence,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.id == this.id &&
          other.name == this.name &&
          other.company == this.company &&
          other.department == this.department &&
          other.title == this.title &&
          other.phoneMobile == this.phoneMobile &&
          other.phoneOffice == this.phoneOffice &&
          other.fax == this.fax &&
          other.email == this.email &&
          other.address == this.address &&
          other.website == this.website &&
          other.memo == this.memo &&
          other.imageFront == this.imageFront &&
          other.imageBack == this.imageBack &&
          other.thumb == this.thumb &&
          other.ocrRaw == this.ocrRaw &&
          other.source == this.source &&
          other.lowConfidence == this.lowConfidence &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> company;
  final Value<String> department;
  final Value<String> title;
  final Value<String> phoneMobile;
  final Value<String> phoneOffice;
  final Value<String> fax;
  final Value<String> email;
  final Value<String> address;
  final Value<String> website;
  final Value<String> memo;
  final Value<String?> imageFront;
  final Value<String?> imageBack;
  final Value<String?> thumb;
  final Value<String> ocrRaw;
  final Value<String> source;
  final Value<String> lowConfidence;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.company = const Value.absent(),
    this.department = const Value.absent(),
    this.title = const Value.absent(),
    this.phoneMobile = const Value.absent(),
    this.phoneOffice = const Value.absent(),
    this.fax = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.website = const Value.absent(),
    this.memo = const Value.absent(),
    this.imageFront = const Value.absent(),
    this.imageBack = const Value.absent(),
    this.thumb = const Value.absent(),
    this.ocrRaw = const Value.absent(),
    this.source = const Value.absent(),
    this.lowConfidence = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.company = const Value.absent(),
    this.department = const Value.absent(),
    this.title = const Value.absent(),
    this.phoneMobile = const Value.absent(),
    this.phoneOffice = const Value.absent(),
    this.fax = const Value.absent(),
    this.email = const Value.absent(),
    this.address = const Value.absent(),
    this.website = const Value.absent(),
    this.memo = const Value.absent(),
    this.imageFront = const Value.absent(),
    this.imageBack = const Value.absent(),
    this.thumb = const Value.absent(),
    this.ocrRaw = const Value.absent(),
    this.source = const Value.absent(),
    this.lowConfidence = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Contact> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? company,
    Expression<String>? department,
    Expression<String>? title,
    Expression<String>? phoneMobile,
    Expression<String>? phoneOffice,
    Expression<String>? fax,
    Expression<String>? email,
    Expression<String>? address,
    Expression<String>? website,
    Expression<String>? memo,
    Expression<String>? imageFront,
    Expression<String>? imageBack,
    Expression<String>? thumb,
    Expression<String>? ocrRaw,
    Expression<String>? source,
    Expression<String>? lowConfidence,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (company != null) 'company': company,
      if (department != null) 'department': department,
      if (title != null) 'title': title,
      if (phoneMobile != null) 'phone_mobile': phoneMobile,
      if (phoneOffice != null) 'phone_office': phoneOffice,
      if (fax != null) 'fax': fax,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (website != null) 'website': website,
      if (memo != null) 'memo': memo,
      if (imageFront != null) 'image_front': imageFront,
      if (imageBack != null) 'image_back': imageBack,
      if (thumb != null) 'thumb': thumb,
      if (ocrRaw != null) 'ocr_raw': ocrRaw,
      if (source != null) 'source': source,
      if (lowConfidence != null) 'low_confidence': lowConfidence,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? company,
      Value<String>? department,
      Value<String>? title,
      Value<String>? phoneMobile,
      Value<String>? phoneOffice,
      Value<String>? fax,
      Value<String>? email,
      Value<String>? address,
      Value<String>? website,
      Value<String>? memo,
      Value<String?>? imageFront,
      Value<String?>? imageBack,
      Value<String?>? thumb,
      Value<String>? ocrRaw,
      Value<String>? source,
      Value<String>? lowConfidence,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return ContactsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      department: department ?? this.department,
      title: title ?? this.title,
      phoneMobile: phoneMobile ?? this.phoneMobile,
      phoneOffice: phoneOffice ?? this.phoneOffice,
      fax: fax ?? this.fax,
      email: email ?? this.email,
      address: address ?? this.address,
      website: website ?? this.website,
      memo: memo ?? this.memo,
      imageFront: imageFront ?? this.imageFront,
      imageBack: imageBack ?? this.imageBack,
      thumb: thumb ?? this.thumb,
      ocrRaw: ocrRaw ?? this.ocrRaw,
      source: source ?? this.source,
      lowConfidence: lowConfidence ?? this.lowConfidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (department.present) {
      map['department'] = Variable<String>(department.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (phoneMobile.present) {
      map['phone_mobile'] = Variable<String>(phoneMobile.value);
    }
    if (phoneOffice.present) {
      map['phone_office'] = Variable<String>(phoneOffice.value);
    }
    if (fax.present) {
      map['fax'] = Variable<String>(fax.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (website.present) {
      map['website'] = Variable<String>(website.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (imageFront.present) {
      map['image_front'] = Variable<String>(imageFront.value);
    }
    if (imageBack.present) {
      map['image_back'] = Variable<String>(imageBack.value);
    }
    if (thumb.present) {
      map['thumb'] = Variable<String>(thumb.value);
    }
    if (ocrRaw.present) {
      map['ocr_raw'] = Variable<String>(ocrRaw.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (lowConfidence.present) {
      map['low_confidence'] = Variable<String>(lowConfidence.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('company: $company, ')
          ..write('department: $department, ')
          ..write('title: $title, ')
          ..write('phoneMobile: $phoneMobile, ')
          ..write('phoneOffice: $phoneOffice, ')
          ..write('fax: $fax, ')
          ..write('email: $email, ')
          ..write('address: $address, ')
          ..write('website: $website, ')
          ..write('memo: $memo, ')
          ..write('imageFront: $imageFront, ')
          ..write('imageBack: $imageBack, ')
          ..write('thumb: $thumb, ')
          ..write('ocrRaw: $ocrRaw, ')
          ..write('source: $source, ')
          ..write('lowConfidence: $lowConfidence, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [contacts];
}

typedef $$ContactsTableCreateCompanionBuilder = ContactsCompanion Function({
  required String id,
  Value<String> name,
  Value<String> company,
  Value<String> department,
  Value<String> title,
  Value<String> phoneMobile,
  Value<String> phoneOffice,
  Value<String> fax,
  Value<String> email,
  Value<String> address,
  Value<String> website,
  Value<String> memo,
  Value<String?> imageFront,
  Value<String?> imageBack,
  Value<String?> thumb,
  Value<String> ocrRaw,
  Value<String> source,
  Value<String> lowConfidence,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$ContactsTableUpdateCompanionBuilder = ContactsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> company,
  Value<String> department,
  Value<String> title,
  Value<String> phoneMobile,
  Value<String> phoneOffice,
  Value<String> fax,
  Value<String> email,
  Value<String> address,
  Value<String> website,
  Value<String> memo,
  Value<String?> imageFront,
  Value<String?> imageBack,
  Value<String?> thumb,
  Value<String> ocrRaw,
  Value<String> source,
  Value<String> lowConfidence,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$ContactsTableFilterComposer extends Composer<_$AppDb, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get department => $composableBuilder(
      column: $table.department, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneMobile => $composableBuilder(
      column: $table.phoneMobile, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneOffice => $composableBuilder(
      column: $table.phoneOffice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fax => $composableBuilder(
      column: $table.fax, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get website => $composableBuilder(
      column: $table.website, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageFront => $composableBuilder(
      column: $table.imageFront, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageBack => $composableBuilder(
      column: $table.imageBack, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumb => $composableBuilder(
      column: $table.thumb, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ocrRaw => $composableBuilder(
      column: $table.ocrRaw, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lowConfidence => $composableBuilder(
      column: $table.lowConfidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ContactsTableOrderingComposer
    extends Composer<_$AppDb, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get department => $composableBuilder(
      column: $table.department, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneMobile => $composableBuilder(
      column: $table.phoneMobile, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneOffice => $composableBuilder(
      column: $table.phoneOffice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fax => $composableBuilder(
      column: $table.fax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get website => $composableBuilder(
      column: $table.website, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memo => $composableBuilder(
      column: $table.memo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageFront => $composableBuilder(
      column: $table.imageFront, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageBack => $composableBuilder(
      column: $table.imageBack, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumb => $composableBuilder(
      column: $table.thumb, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ocrRaw => $composableBuilder(
      column: $table.ocrRaw, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lowConfidence => $composableBuilder(
      column: $table.lowConfidence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$AppDb, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get department => $composableBuilder(
      column: $table.department, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get phoneMobile => $composableBuilder(
      column: $table.phoneMobile, builder: (column) => column);

  GeneratedColumn<String> get phoneOffice => $composableBuilder(
      column: $table.phoneOffice, builder: (column) => column);

  GeneratedColumn<String> get fax =>
      $composableBuilder(column: $table.fax, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get website =>
      $composableBuilder(column: $table.website, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get imageFront => $composableBuilder(
      column: $table.imageFront, builder: (column) => column);

  GeneratedColumn<String> get imageBack =>
      $composableBuilder(column: $table.imageBack, builder: (column) => column);

  GeneratedColumn<String> get thumb =>
      $composableBuilder(column: $table.thumb, builder: (column) => column);

  GeneratedColumn<String> get ocrRaw =>
      $composableBuilder(column: $table.ocrRaw, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get lowConfidence => $composableBuilder(
      column: $table.lowConfidence, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ContactsTableTableManager extends RootTableManager<
    _$AppDb,
    $ContactsTable,
    Contact,
    $$ContactsTableFilterComposer,
    $$ContactsTableOrderingComposer,
    $$ContactsTableAnnotationComposer,
    $$ContactsTableCreateCompanionBuilder,
    $$ContactsTableUpdateCompanionBuilder,
    (Contact, BaseReferences<_$AppDb, $ContactsTable, Contact>),
    Contact,
    PrefetchHooks Function()> {
  $$ContactsTableTableManager(_$AppDb db, $ContactsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> company = const Value.absent(),
            Value<String> department = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> phoneMobile = const Value.absent(),
            Value<String> phoneOffice = const Value.absent(),
            Value<String> fax = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<String> website = const Value.absent(),
            Value<String> memo = const Value.absent(),
            Value<String?> imageFront = const Value.absent(),
            Value<String?> imageBack = const Value.absent(),
            Value<String?> thumb = const Value.absent(),
            Value<String> ocrRaw = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> lowConfidence = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactsCompanion(
            id: id,
            name: name,
            company: company,
            department: department,
            title: title,
            phoneMobile: phoneMobile,
            phoneOffice: phoneOffice,
            fax: fax,
            email: email,
            address: address,
            website: website,
            memo: memo,
            imageFront: imageFront,
            imageBack: imageBack,
            thumb: thumb,
            ocrRaw: ocrRaw,
            source: source,
            lowConfidence: lowConfidence,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> name = const Value.absent(),
            Value<String> company = const Value.absent(),
            Value<String> department = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> phoneMobile = const Value.absent(),
            Value<String> phoneOffice = const Value.absent(),
            Value<String> fax = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<String> website = const Value.absent(),
            Value<String> memo = const Value.absent(),
            Value<String?> imageFront = const Value.absent(),
            Value<String?> imageBack = const Value.absent(),
            Value<String?> thumb = const Value.absent(),
            Value<String> ocrRaw = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> lowConfidence = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ContactsCompanion.insert(
            id: id,
            name: name,
            company: company,
            department: department,
            title: title,
            phoneMobile: phoneMobile,
            phoneOffice: phoneOffice,
            fax: fax,
            email: email,
            address: address,
            website: website,
            memo: memo,
            imageFront: imageFront,
            imageBack: imageBack,
            thumb: thumb,
            ocrRaw: ocrRaw,
            source: source,
            lowConfidence: lowConfidence,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ContactsTable, Contact>(table),
                    BaseReferences<_$AppDb, $ContactsTable, Contact>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ContactsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $ContactsTable,
    Contact,
    $$ContactsTableFilterComposer,
    $$ContactsTableOrderingComposer,
    $$ContactsTableAnnotationComposer,
    $$ContactsTableCreateCompanionBuilder,
    $$ContactsTableUpdateCompanionBuilder,
    (Contact, BaseReferences<_$AppDb, $ContactsTable, Contact>),
    Contact,
    PrefetchHooks Function()>;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
}
