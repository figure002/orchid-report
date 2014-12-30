#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import sys

from nbclassify import db
from sqlalchemy import asc, distinct
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.sql import functions as func
from sqlalchemy.orm import configure_mappers

def main():
    parser = argparse.ArgumentParser(
        description="Print database statistics in LaTeX format."
    )
    parser.add_argument(
        "meta",
        metavar="META",
        help="Path to the metadata file."
    )
    subparsers = parser.add_subparsers(
        help="Specify which task to start.",
        dest="task"
    )

    parser_db_stats = subparsers.add_parser(
        "db_stats",
        help="Print stats as LaTeX commands",
        description=""
    )

    parser_taxa = subparsers.add_parser(
        "taxa",
        help="Taxa table with photo count per taxon.",
        description=""
    )
    parser_taxa.add_argument(
        "--col",
        metavar="N",
        type=int,
        default=1,
        help="The number of species per row.")

    parser_taxa_summary = subparsers.add_parser(
        "taxa_summary",
        help="Summarised taxa table with photo count per taxon. Only prints " \
            "the section and species count per genus.",
        description=""
    )

    args = parser.parse_args()

    if args.task == 'db_stats':
        db_stats(args.meta)
    if args.task == 'taxa':
        photo_stats(args.meta, args.col)
    if args.task == 'taxa_summary':
        photo_stats_summary(args.meta)

def db_stats(db_path):
    with db.session_scope(db_path) as (session, metadata):
        print "\\newcommand{{\\PhotoCount}}{{{0}}}".format(get_photo_count(session, metadata))
        print "\\newcommand{{\\SpeciesCount}}{{{0}}}".format(get_species_count(session, metadata))

def photo_stats(db_path, n_col=1):
    with db.session_scope(db_path) as (session, metadata):
        q = db.get_taxa_photo_count(session, metadata)

        # Table header.
        #sys.stdout.write("\\toprule\n")
        #sys.stdout.write(" & ".join(["\\textbf{Taxa} & \\textbf{Photos}"] * n_col))
        #sys.stdout.write(" \\\\\n")
        #sys.stdout.write("\\midrule\n")

        # Table body.
        current_genus = None
        current_section = None
        species_count = 0
        for genus, section, species, photo in q:
            if genus != current_genus:
                if current_genus:
                    sys.stdout.write(" \\\\\\\\\n")
                sys.stdout.write("\\textit{{{0}}} \\\\\n".format(genus))
                sys.stdout.write("\\midrule\n".format(genus))

            if section != current_section:
                current_section = section
                species_count = 0
                if genus == current_genus:
                    sys.stdout.write(" \\\\\n")
                sys.stdout.write("Section \\textit{{{0}}} \\\\\n".format(section))

            if genus != current_genus:
                current_genus = genus

            # Print two species per row.
            if species_count > 0:
                if species_count % n_col == 0:
                    sys.stdout.write(" \\\\\n")
                else:
                    sys.stdout.write(" & ")

            # Print species.
            sys.stdout.write("\\textit{{{0}. {1}}} & {2}".format(current_genus[0], species, photo))

            species_count += 1

def photo_stats_summary(db_path):
    with db.session_scope(db_path) as (session, metadata):
        q = get_taxa_photo_count_summary(session, metadata)
        q = q.order_by(asc('photos'))
        for genus, section, species, photo in q:
            print "\\textit{{{0}}} & {1} & {2} & {3} \\\\".format(genus, section, species, photo)


def get_photo_count(session, metadata):
    Base = automap_base(metadata=metadata)
    Base.prepare()
    configure_mappers()
    Photo = Base.classes.photos
    return session.query(func.count(Photo.id)).one()[0]

def get_species_count(session, metadata):
    q = db.get_taxa_photo_count(session, metadata)
    return len(q.all())

def get_taxa_photo_count_summary(session, metadata):
    """Return the section count, species count, and photo count per genus."""
    Base = automap_base(metadata=metadata)
    Base.prepare()
    configure_mappers()

    # Get the table classes.
    Photo = Base.classes.photos
    Taxon = Base.classes.taxa
    Rank = Base.classes.ranks

    stmt_genus = session.query(Photo.id, Taxon.name.label('genus')).\
        join(Photo.taxa_collection, Taxon.ranks).\
        filter(Rank.name == 'genus').subquery()

    stmt_section = session.query(Photo.id, Taxon.name.label('section')).\
        join(Photo.taxa_collection, Taxon.ranks).\
        filter(Rank.name == 'section').subquery()

    stmt_species = session.query(Photo.id, Taxon.name.label('species')).\
        join(Photo.taxa_collection, Taxon.ranks).\
        filter(Rank.name == 'species').subquery()

    q = session.query('genus',
            func.count(distinct(stmt_section.c.section)),
            func.count(distinct(stmt_species.c.species)),
            func.count(Photo.id).label('photos')).\
        select_from(Photo).\
        join(stmt_genus, stmt_genus.c.id == Photo.id).\
        outerjoin(stmt_section, stmt_section.c.id == Photo.id).\
        join(stmt_species, stmt_species.c.id == Photo.id).\
        group_by('genus').\
        order_by('genus')

    return q

if __name__ == "__main__":
    main()
