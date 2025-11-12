import { MigrationInterface, QueryRunner } from "typeorm";

export class AddDeletedAtToProducts1695043200000 implements MigrationInterface {
    name = 'AddDeletedAtToProducts1695043200000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(
            `ALTER TABLE \`products\` ADD \`deletedAt\` datetime(6) NULL`
        );
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(
            `ALTER TABLE \`products\` DROP COLUMN \`deletedAt\``
        );
    }
}