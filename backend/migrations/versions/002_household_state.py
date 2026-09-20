"""household_state: ключ-значение синк между телефонами.

Revision ID: 002_household_state
Revises: 001_initial_schema
Create Date: 2026-07-12
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "002_household_state"
down_revision: str | None = "001_initial_schema"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "household_state",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("key", sa.String(length=64), nullable=False),
        sa.Column("value", sa.JSON(), nullable=False),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("user_id", "key"),
    )


def downgrade() -> None:
    op.drop_table("household_state")
