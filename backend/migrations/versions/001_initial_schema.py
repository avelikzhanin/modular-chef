"""Initial schema: users, modules, weekly_menus, shopping_lists, user_dishes, storage_items.

Revision ID: 001_initial_schema
Revises:
Create Date: 2026-05-27
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "001_initial_schema"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(as_uuid=True, native_uuid=True), primary_key=True),
        sa.Column("email", sa.String(length=255), nullable=False, unique=True),
        sa.Column("display_name", sa.String(length=120), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "modules",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("emoji", sa.String(length=16), nullable=False),
        sa.Column("category", sa.String(length=32), nullable=False),
        sa.Column("tags", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("methods", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("storage_zone", sa.String(length=16), nullable=False),
        sa.Column("storage_days", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("storage_tip", sa.Text(), nullable=True),
        sa.Column("calories_per_100g", sa.Integer(), nullable=True),
        sa.Column("prep_minutes", sa.Integer(), nullable=True),
    )
    op.create_index("ix_modules_category", "modules", ["category"])

    op.create_table(
        "weekly_menus",
        sa.Column("id", sa.Uuid(as_uuid=True, native_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True, native_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("starts_on", sa.Date(), nullable=True),
        sa.Column("menu_json", sa.JSON(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column(
            "generated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_weekly_menus_user", "weekly_menus", ["user_id"])
    op.create_index("ix_weekly_menus_user_active", "weekly_menus", ["user_id", "is_active"])

    op.create_table(
        "shopping_lists",
        sa.Column("id", sa.Uuid(as_uuid=True, native_uuid=True), primary_key=True),
        sa.Column(
            "menu_id",
            sa.Uuid(as_uuid=True, native_uuid=True),
            sa.ForeignKey("weekly_menus.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("week_index", sa.Integer(), nullable=False),
        sa.Column("items_json", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column(
            "generated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_shopping_lists_menu", "shopping_lists", ["menu_id"])

    op.create_table(
        "user_dishes",
        sa.Column("id", sa.Uuid(as_uuid=True, native_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True, native_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.String(length=160), nullable=False),
        sa.Column("emoji", sa.String(length=16), nullable=True),
        sa.Column("tags", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("recipe_text", sa.Text(), nullable=True),
        sa.Column("storage_zone", sa.String(length=16), nullable=True),
        sa.Column("storage_days", sa.Integer(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_user_dishes_user", "user_dishes", ["user_id"])

    op.create_table(
        "storage_items",
        sa.Column("id", sa.Uuid(as_uuid=True, native_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            sa.Uuid(as_uuid=True, native_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "module_id",
            sa.String(length=64),
            sa.ForeignKey("modules.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("module_name", sa.String(length=160), nullable=False),
        sa.Column("emoji", sa.String(length=16), nullable=True),
        sa.Column("zone", sa.String(length=16), nullable=False),
        sa.Column("portion_count", sa.Integer(), nullable=False, server_default="1"),
        sa.Column(
            "added_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_storage_items_user", "storage_items", ["user_id"])
    op.create_index("ix_storage_items_user_zone", "storage_items", ["user_id", "zone"])


def downgrade() -> None:
    op.drop_index("ix_storage_items_user_zone", table_name="storage_items")
    op.drop_index("ix_storage_items_user", table_name="storage_items")
    op.drop_table("storage_items")

    op.drop_index("ix_user_dishes_user", table_name="user_dishes")
    op.drop_table("user_dishes")

    op.drop_index("ix_shopping_lists_menu", table_name="shopping_lists")
    op.drop_table("shopping_lists")

    op.drop_index("ix_weekly_menus_user_active", table_name="weekly_menus")
    op.drop_index("ix_weekly_menus_user", table_name="weekly_menus")
    op.drop_table("weekly_menus")

    op.drop_index("ix_modules_category", table_name="modules")
    op.drop_table("modules")

    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
